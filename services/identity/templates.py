"""Versioned text templates used by both Admin previews and actual SMTP delivery."""
import html
import re
from .core import AuthError

TEMPLATES = {
 'email-verification': ('Confirm your email', 'Confirm your email address to activate your account.'),
 'welcome': ('Welcome', 'Your account is ready. You can now sign in to the app.'),
 'password-reset': ('Reset your password', 'Use this link to choose a new password. It expires in one hour.'),
 'password-changed': ('Password changed', 'Your password was changed. If this was not you, contact support.'),
 'security-alert': ('Account security alert', 'An important security change occurred on your account.'),
}
EVENTS = {
 'email-verification': 'Email registration, resend or explicit email-password linking',
 'welcome': 'First social registration or first successful email confirmation (once per account)',
 'password-reset': 'Eligible forgot-password request',
 'password-changed': 'Successful password reset',
 'security-alert': 'Reserved; no automatic trigger currently enabled',
}
BRANDS = {'statz': 'STATZ', 'bliss': 'Bliss', 'sixth': 'Sixth', 'split': 'Split Paper'}


def validate(key, value):
    if key not in TEMPLATES: raise AuthError('template_not_found', 404)
    if not isinstance(value, dict) or set(value) - {'subject','body','expected_revision','actor'}:
        raise AuthError('invalid_template')
    for field, limit in [('subject',200),('body',12000)]:
        text=value.get(field)
        if not isinstance(text,str) or not text.strip() or len(text)>limit or '\x00' in text:
            raise AuthError('invalid_template')
        if field=='subject' and ('\r' in text or '\n' in text): raise AuthError('invalid_template')
        remaining=text.replace('{{app_name}}','')
        if '{{' in remaining or '}}' in remaining: raise AuthError('unknown_template_variable')
    return value


def get(identity, key, c=None):
    if key not in TEMPLATES: raise AuthError('template_not_found',404)
    if c is None:
        with identity.engine.connect() as connection: return get(identity,key,connection)
    row=identity.one(c,'SELECT subject,body,revision,updated_at FROM auth_email_templates WHERE template_key=:k',k=key)
    subject,body=TEMPLATES[key]
    return dict(key=key,subject=row['subject'] if row else subject,body=row['body'] if row else body,
                revision=row['revision'] if row else 0,updated_at=row['updated_at'] if row else None,
                source='database' if row else 'code_default',variables=['app_name'],
                action_link_managed=key in ('email-verification','password-reset'),
                trigger=EVENTS[key],automatically_triggered=key!='security-alert')


def save(identity,key,value):
    validate(key,value)
    revision=value.get('expected_revision')
    actor=value.get('actor')
    if type(revision)!=int or revision<0: raise AuthError('expected_revision_required')
    if not isinstance(actor,str) or not actor.strip() or len(actor)>120 or any(ord(x)<32 for x in actor):
        raise AuthError('admin_actor_required')
    with identity.engine.begin() as c:
        now=identity.now()
        params=dict(k=key,s=value['subject'],b=value['body'],r=revision,t=now,a=actor)
        if revision==0:
            if identity.one(c,'SELECT template_key FROM auth_email_templates WHERE template_key=:k',k=key):
                raise AuthError('template_revision_conflict',409)
            identity.execute(c,'INSERT INTO auth_email_templates(template_key,subject,body,revision,updated_at) VALUES(:k,:s,:b,1,:t)',**params)
        else:
            changed=identity.execute(c,'UPDATE auth_email_templates SET subject=:s,body=:b,revision=revision+1,updated_at=:t WHERE template_key=:k AND revision=:r',**params).rowcount
            if changed!=1: raise AuthError('template_revision_conflict',409)
        identity.execute(c,'INSERT INTO auth_template_revisions(template_key,revision,subject,body,updated_at,actor) VALUES(:k,:r+1,:s,:b,:t,:a)',**params)
        return get(identity,key,c)


def render(identity,key,value=None,action_url=None):
    value=validate(key,value) if value is not None else get(identity,key)
    brand=BRANDS[identity.product]
    subject=value['subject'].replace('{{app_name}}',brand)
    body=value['body'].replace('{{app_name}}',brand)
    label='' if identity.config['environment']=='production' else '['+identity.config['environment'].upper()+'] '
    text=brand+'\n\n'+body+(('\n\n'+action_url) if action_url else '')
    markup='<!doctype html><html><body><h1>'+html.escape(brand)+'</h1><h2>'+html.escape(subject)+'</h2><p>'+html.escape(body).replace('\n','<br>')+'</p>'
    if action_url: markup+='<p><a href="'+html.escape(action_url,quote=True)+'">'+html.escape(subject)+'</a></p>'
    return dict(subject=label+brand+' — '+subject,text=text,html=markup+'</body></html>')
