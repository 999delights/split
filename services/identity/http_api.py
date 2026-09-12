"""Mount this blueprint in a product backend; no domain data is exposed here."""
from flask import Blueprint, jsonify, request, make_response
from pathlib import Path
import secrets
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from .core import AuthError


def blueprint(identity):
    bp=Blueprint('identity',__name__)
    @bp.before_request
    def body_limit():
        if request.content_length and request.content_length>32768:
            raise AuthError('request_too_large',413)

    @bp.after_request
    def private(response):
        response.headers['Cache-Control']='no-store'
        response.headers['Referrer-Policy']='no-referrer'
        return response

    @bp.errorhandler(AuthError)
    def auth_error(error):
        return jsonify(error=error.code),error.status

    @bp.errorhandler(IntegrityError)
    def conflict(_error):
        return jsonify(error='request_conflict_retry'),409

    @bp.errorhandler(SQLAlchemyError)
    def database_error(_error):
        # SQLAlchemy exceptions may include bound personal data; never return/log them.
        return jsonify(error='authentication_unavailable'),503

    def body():
        data=request.get_json(silent=True)
        if not isinstance(data,dict):raise AuthError('invalid_request')
        return data

    def user():
        header=request.headers.get('Authorization','')
        return identity.authenticate(header[7:] if header.startswith('Bearer ') else '')

    @bp.post('/register')
    def register():
        d=body();return jsonify(identity.register(d.get('email'),d.get('password'),d.get('name'),request.remote_addr))

    @bp.post('/login')
    def login():
        d=body();return jsonify(identity.login(d.get('email'),d.get('password'),d.get('device'),request.remote_addr))

    @bp.post('/resend-verification')
    def resend():
        return jsonify(identity.request_email(body().get('email'),'verify',request.remote_addr))

    @bp.post('/forgot-password')
    def forgot():
        return jsonify(identity.request_email(body().get('email'),'reset',request.remote_addr))

    @bp.post('/verify-email')
    def verify():
        return jsonify(identity.consume(body().get('token'),'verify'))

    @bp.post('/reset-password')
    def reset():
        d=body();return jsonify(identity.consume(d.get('token'),'reset',d.get('password')))

    @bp.post('/challenge')
    def challenge():
        return jsonify(identity.challenge(request.remote_addr))

    @bp.post('/google')
    def google():
        d=body();return jsonify(identity.social('google',d.get('id_token'),None,d.get('device'),request.remote_addr))

    @bp.post('/apple')
    def apple():
        d=body();return jsonify(identity.social('apple',d.get('id_token'),d.get('nonce'),d.get('device'),request.remote_addr))

    @bp.post('/link/google')
    def link_google():
        u=user();d=body()
        return jsonify(identity.social('google',d.get('id_token'),None,None,request.remote_addr,link_user=u['id']))

    @bp.post('/link/apple')
    def link_apple():
        u=user();d=body()
        return jsonify(identity.social('apple',d.get('id_token'),d.get('nonce'),None,request.remote_addr,link_user=u['id']))

    @bp.post('/link/email')
    def link_email():
        u=user();d=body()
        return jsonify(identity.link_email(u['id'],d.get('email'),d.get('password'),request.remote_addr))

    @bp.post('/refresh')
    def refresh():
        d=body();token=d.get('refresh_token')
        if not isinstance(token,str) or len(token)>256:raise AuthError('invalid_session',401)
        return jsonify(identity.refresh(token,d.get('device')))

    @bp.get('/me')
    def me():
        return jsonify(user=user())

    @bp.post('/methods')
    def methods():
        u=user()
        return jsonify(identity.methods(u['id']))

    @bp.post('/logout')
    def logout():
        u=user();d=body()
        token=d.get('refresh_token','')
        if not isinstance(token,str) or not isinstance(d.get('all_devices',False),bool):raise AuthError('invalid_request')
        identity.logout(u['id'],token,d.get('all_devices',False))
        return jsonify(ok=True)
    @bp.get('/action')
    def action_page():
        nonce=secrets.token_urlsafe(24)
        response=make_response(Path(__file__).with_name('action.html').read_text().replace('{{nonce}}',nonce))
        response.headers['Content-Security-Policy']="default-src 'none'; script-src 'nonce-"+nonce+"'; connect-src 'self'; form-action 'none'; base-uri 'none'; frame-ancestors 'none'"
        return response
    return bp
