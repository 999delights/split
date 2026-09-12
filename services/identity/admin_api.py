"""Product-scoped Admin v1 contract. No credential material crosses this boundary."""
from datetime import datetime, timezone
from pathlib import Path
import os
import secrets
from flask import Blueprint,request,jsonify
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from .core import AuthError
from . import templates


def iso(value):
    if value is None: return None
    if isinstance(value,(int,float)): value=datetime.fromtimestamp(value,timezone.utc)
    elif isinstance(value,str): value=datetime.fromisoformat(value.replace('Z','+00:00'))
    if value.tzinfo is None: value=value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat().replace('+00:00','Z')


def dates(row):
    return {k:iso(v) if k.endswith('_at') else v for k,v in dict(row).items()}


def blueprint(identity):
    bp=Blueprint('account_admin_'+identity.product,__name__)
    def token(scope):
        # Optional keys: absent Admin setup never breaks application login.
        path=identity.config.get('admin_'+scope+'_token_file')
        if path:
            try: return Path(path).read_text().strip()
            except OSError: return ''
        return os.environ.get(identity.product.upper()+'_ADMIN_'+scope.upper()+'_TOKEN','')
    @bp.before_request
    def authorize():
        scope='write' if request.method=='PATCH' else 'read'
        supplied=request.headers.get('Authorization','')
        if not supplied.startswith('Bearer '): return jsonify(error='unauthorized'),401
        expected=token(scope)
        if len(expected)<32 or not secrets.compare_digest(expected,supplied[7:]): return jsonify(error='unauthorized'),401
        if request.content_length and request.content_length>32768: raise AuthError('request_too_large',413)
    @bp.after_request
    def private(response):
        response.headers['Cache-Control']='no-store'
        response.headers['Referrer-Policy']='no-referrer'
        response.headers['X-Content-Type-Options']='nosniff'
        return response
    @bp.errorhandler(AuthError)
    def auth_error(error): return jsonify(error=error.code),error.status
    @bp.errorhandler(IntegrityError)
    def conflict(_): return jsonify(error='request_conflict_retry'),409
    @bp.errorhandler(SQLAlchemyError)
    def unavailable(_): return jsonify(error='admin_data_unavailable'),503
    def query(c,sql,**params): return [dict(x) for x in identity.execute(c,sql,**params).mappings()]
    def pagination():
        try: limit=int(request.args.get('limit',50));offset=int(request.args.get('offset',0))
        except ValueError: raise AuthError('invalid_pagination')
        if not 1<=limit<=100 or offset<0: raise AuthError('invalid_pagination')
        return limit,offset
    def account(c,uid):
        rows=query(c,f'SELECT {identity.user_key} AS id,display_name,email,status,created_at,last_login_at,last_login_provider FROM app_users WHERE {identity.user_key}=:u',u=uid)
        if not rows: raise AuthError('user_not_found',404)
        return dates(rows[0])
    def summary(c,row):
        uid=row['id'];row=dates(row)
        row['login_methods']=[r['provider'] for r in query(c,"SELECT DISTINCT provider FROM auth_identities WHERE user_id=:u AND provider IN ('google','apple') ORDER BY provider",u=uid)]
        row['has_password']=bool(identity.one(c,'SELECT user_id FROM auth_passwords WHERE user_id=:u',u=uid))
        if row['has_password']: row['login_methods'].append('email')
        email=identity.one(c,'SELECT verified_at,confirmed_at,verification_source FROM auth_email_addresses WHERE user_id=:u AND email=:e',u=uid,e=row['email'])
        row['email_verified']=bool(email and email['verified_at'] is not None)
        row['email_confirmed_at']=iso(email['confirmed_at']) if email else None
        row['verification_source']=email['verification_source'] if email else None
        last=identity.one(c,'SELECT provider FROM auth_sessions WHERE user_id=:u AND id=family_id ORDER BY created_at DESC,id DESC LIMIT 1',u=uid)
        # Original family rows represent login, descendants only refresh.
        row['last_login_provider']=row.get('last_login_provider') or (last['provider'] if last else None)
        row['active_sessions']=identity.one(c,'SELECT COUNT(DISTINCT family_id) n FROM auth_sessions WHERE user_id=:u AND revoked_at IS NULL AND consumed_at IS NULL AND expires_at>:n',u=uid,n=identity.now())['n'] if row['status']=='active' else 0
        return row
    def session_page(c,uid,limit,offset,status):
        families=query(c,'SELECT family_id,MIN(created_at) AS created_at,MAX(created_at) AS last_refresh_at FROM auth_sessions WHERE user_id=:u GROUP BY family_id ORDER BY MAX(created_at) DESC,family_id LIMIT :l OFFSET :o',u=uid,l=limit,o=offset)
        result=[]
        for family in families:
            latest=identity.one(c,'SELECT id,device_id,device_label,provider,expires_at,consumed_at,revoked_at FROM auth_sessions WHERE user_id=:u AND family_id=:f ORDER BY (consumed_at IS NULL) DESC,created_at DESC,id DESC LIMIT 1',u=uid,f=family['family_id'])
            state='revoked' if latest['revoked_at'] is not None else 'expired' if latest['expires_at']<=identity.now() else 'rotated' if latest['consumed_at'] is not None else 'account_disabled' if status!='active' else 'active'
            result.append(dates({**family,**latest,'status':state}))
        total=identity.one(c,'SELECT COUNT(DISTINCT family_id) n FROM auth_sessions WHERE user_id=:u',u=uid)['n']
        return dict(sessions=result,total=total,limit=limit,offset=offset)
    @bp.get('/contract')
    def contract():
        return jsonify(version=1,product=identity.product,environment=identity.config['environment'],timestamps='ISO-8601 UTC',
            sessions_grouped_by='family_id',session_active_is_not_presence=True,
            providers_configured={p:bool(identity.config.get(p+'_client_ids')) for p in ('google','apple')},
            provider_configuration_is_not_end_to_end_verification=True,
            email=dict(enabled=bool(identity.config.get('mail_enabled')),delivery_evidence='SMTP acceptance, not inbox delivery',templates_editable=True),
            legacy_devices='Old sessions without device_id retain labels; never inferred as physical devices')
    @bp.get('/users')
    def users():
        limit,offset=pagination();search=request.args.get('q','')
        if len(search)>160: raise AuthError('invalid_search')
        where=' WHERE display_name LIKE :q OR email LIKE :q' if search else ''
        with identity.engine.connect() as c:
            rows=query(c,f'SELECT {identity.user_key} AS id,display_name,email,status,created_at,last_login_at,last_login_provider FROM app_users'+where+f' ORDER BY created_at,{identity.user_key} LIMIT :l OFFSET :o',q='%'+search+'%',l=limit,o=offset)
            total=identity.one(c,'SELECT COUNT(*) n FROM app_users'+where,q='%'+search+'%')['n']
            return jsonify(users=[summary(c,r) for r in rows],total=total,limit=limit,offset=offset)
    @bp.get('/users/<uid>')
    def detail(uid):
        with identity.engine.connect() as c:
            result=summary(c,account(c,uid))
            result['identities']=[dates(r) for r in query(c,'SELECT provider,email,email_verified,created_at,last_login_at FROM auth_identities WHERE user_id=:u',u=uid)]
            for item in result['identities']:
                if item['email_verified'] is not None:item['email_verified']=bool(item['email_verified'])
            result['email_addresses']=[dates(r) for r in query(c,'SELECT email,verified_at,confirmed_at,verification_source FROM auth_email_addresses WHERE user_id=:u',u=uid)]
            result['devices']=[dates(r) for r in query(c,'SELECT id,platform,name,model,app_version,created_at,last_seen_at,revoked_at FROM user_devices WHERE user_id=:u ORDER BY last_seen_at DESC',u=uid)]
            page=session_page(c,uid,50,0,result['status']);result['sessions']=page['sessions'];result['sessions_total']=page['total']
            if identity.product=='bliss':result['agents']=[dates(r) for r in query(c,'SELECT id,name,version,created_at,last_seen_at,revoked_at FROM agents WHERE owner_user_id=:u',u=uid)]
            return jsonify(user=result)
    @bp.get('/users/<uid>/sessions')
    def sessions(uid):
        limit,offset=pagination()
        with identity.engine.connect() as c:
            user=account(c,uid)
            return jsonify(session_page(c,uid,limit,offset,user['status']))
    @bp.get('/users/<uid>/events')
    def events(uid):
        limit,offset=pagination()
        with identity.engine.connect() as c:
            account(c,uid)
            rows=query(c,'SELECT id,event_type,provider,created_at FROM auth_security_events WHERE user_id=:u ORDER BY created_at DESC,id DESC LIMIT :l OFFSET :o',u=uid,l=limit,o=offset)
            return jsonify(events=[dates(r) for r in rows],total=identity.one(c,'SELECT COUNT(*) n FROM auth_security_events WHERE user_id=:u',u=uid)['n'],limit=limit,offset=offset)
    @bp.get('/email-outbox')
    def outbox():
        limit,offset=pagination();uid=request.args.get('user_id');where=' WHERE user_id=:u' if uid else ''
        with identity.engine.connect() as c:
            rows=query(c,'SELECT id,user_id,recipient,template,status,attempts,next_attempt_at,created_at,sent_at,error_code FROM auth_email_outbox'+where+' ORDER BY created_at DESC,id DESC LIMIT :l OFFSET :o',u=uid,l=limit,o=offset)
            return jsonify(messages=[dates(r) for r in rows],total=identity.one(c,'SELECT COUNT(*) n FROM auth_email_outbox'+where,u=uid)['n'],limit=limit,offset=offset)
    @bp.get('/email-templates')
    def template_list():
        with identity.engine.connect() as c:return jsonify(templates=[dates(templates.get(identity,k,c)) for k in templates.TEMPLATES])
    @bp.get('/email-templates/<key>/revisions')
    def template_history(key):
        if key not in templates.TEMPLATES: raise AuthError('template_not_found',404)
        limit,offset=pagination()
        with identity.engine.connect() as c:
            rows=query(c,'SELECT revision,subject,body,updated_at,actor FROM auth_template_revisions WHERE template_key=:k ORDER BY revision DESC LIMIT :l OFFSET :o',k=key,l=limit,o=offset)
            return jsonify(revisions=[dates(r) for r in rows],total=identity.one(c,'SELECT COUNT(*) n FROM auth_template_revisions WHERE template_key=:k',k=key)['n'],limit=limit,offset=offset)
    @bp.patch('/email-templates/<key>')
    def template_update(key): return jsonify(template=dates(templates.save(identity,key,request.get_json(silent=True))))
    @bp.post('/email-templates/<key>/preview')
    def template_preview(key):
        data=request.get_json(silent=True)
        if not isinstance(data,dict): raise AuthError('invalid_template')
        action='https://preview.invalid/confirmation' if key in ('email-verification','password-reset') else None
        return jsonify(preview=templates.render(identity,key,data or None,action),sends_email=False)
    return bp
