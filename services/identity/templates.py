"""Versioned text templates used by both Admin previews and actual SMTP delivery."""
import re
from datetime import datetime, timezone
from .core import AuthError

from urllib.parse import urlsplit, parse_qs
from .email_brand import BRAND
from .email_layout import render_html

TEMPLATES = BRAND['templates']
EVENTS = {
 'email-verification': 'Email registration, resend or explicit email-password linking',
 'welcome': 'Initial social registration or initial email registration confirmation (once per account)',
 'password-reset': 'Eligible forgot-password request',
 'password-changed': 'Successful password reset',
 'identity-linked': 'Successful new Google/Apple link or confirmed email-password link; once per identity, to a verified contact',
 'security-alert': 'Reserved; no automatic trigger currently enabled',
}
LABELS = {'welcome':'WELCOME ABOARD', 'email-verification':'VERIFY YOUR EMAIL',
          'password-reset':'RESET YOUR PASSWORD', 'password-changed':'PASSWORD UPDATED',
          'identity-linked':'SIGN-IN METHOD CONNECTED', 'security-alert':'ACCOUNT SECURITY'}
ACTIONS = {'email-verification':('Confirm email address','verify'), 'password-reset':('Choose a new password','reset')}
NOTES = {
 'welcome':'Keep your sign-in details private. You can review connected sign-in methods in the app.',
 'email-verification':'This confirmation link expires in 24 hours and can be used once. If you did not request it, you can ignore this email.',
 'password-reset':'This reset link expires in one hour and can be used once. If you did not request it, your password has not changed; ignore this email.',
 'password-changed':'If you did not make this change, request a password reset from the app and contact support.',
 'identity-linked':'If you did not add this method, open the app directly and contact support. Never share your sign-in credentials.',
 'security-alert':'Open the app directly to review your account. Contact support if you do not recognize a change.',
}


def variables(key):
    return ['app_name','display_name'] + (['provider'] if key=='identity-linked' else [])


def validate(key, value):
    if key not in TEMPLATES: raise AuthError('template_not_found', 404)
    if not isinstance(value, dict) or set(value) - {'subject','body','expected_revision','actor'}:
        raise AuthError('invalid_template')
    for field, limit in [('subject',200),('body',12000)]:
        text=value.get(field)
        if not isinstance(text,str) or not text.strip() or len(text)>limit or '\x00' in text:
            raise AuthError('invalid_template')
        if field=='subject' and ('\r' in text or '\n' in text): raise AuthError('invalid_template')
        remaining=text
        for name in variables(key): remaining=remaining.replace('{{'+name+'}}','')
        if '{{' in remaining or '}}' in remaining: raise AuthError('unknown_template_variable')
    return value


def preview_context(value):
    """Only public, bounded personalization fields; never recipient/URL/token input."""
    if not isinstance(value,dict) or set(value)-{'display_name','provider'}:
        raise AuthError('invalid_preview_context')
    if 'display_name' in value:
        name=value['display_name']
        if (not isinstance(name,str) or not name.strip() or len(name)>120 or
            any(ord(char)<32 or ord(char)==127 for char in name)):
            raise AuthError('invalid_preview_context')
    if 'provider' in value and (not isinstance(value['provider'],str) or value['provider'] not in ('google','apple','email')):
        raise AuthError('invalid_preview_context')
    return {'display_name':'Alex','provider':'google','preview':True,**value}


def get(identity, key, c=None):
    if key not in TEMPLATES: raise AuthError('template_not_found',404)
    if c is None:
        with identity.engine.connect() as connection: return get(identity,key,connection)
    row=identity.one(c,'SELECT subject,body,revision,updated_at FROM auth_email_templates WHERE template_key=:k',k=key)
    subject,body=TEMPLATES[key]
    return dict(key=key,subject=row['subject'] if row else subject,body=row['body'] if row else body,
                revision=row['revision'] if row else 0,updated_at=row['updated_at'] if row else None,
                source='database' if row else 'code_default',variables=variables(key),
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


def _action_url(identity,key,url):
    if not url: return None
    if key not in ACTIONS or not isinstance(url,str): raise AuthError('invalid_action_link')
    parsed=urlsplit(url)
    if url=='https://preview.invalid/confirmation': return url
    base=identity.config['public_url'].rstrip('/')+'/action'
    parts=parse_qs(parsed.fragment)
    token=parts.get('token',[])
    if (url.split('#',1)[0]!=base or parsed.query or
        parts.get('purpose')!=[ACTIONS[key][1]] or set(parts)!={'purpose','token'} or
        len(token)!=1 or not re.fullmatch(r'[A-Za-z0-9_-]{20,200}',token[0])):
        raise AuthError('invalid_action_link')
    return url


def render(identity,key,value=None,action_url=None,context=None):
    if key not in TEMPLATES: raise AuthError('template_not_found',404)
    if identity.product!=BRAND['product']: raise AuthError('email_brand_mismatch')
    value=validate(key,value) if value is not None else get(identity,key)
    context=context or {}
    name=context.get('display_name') or 'there'
    # Names are plain text, including in Subject. Strip header controls before interpolation.
    name=' '.join(re.sub(r'[\x00-\x1f\x7f]', ' ', str(name)).split())[:120] or 'there'
    provider={'google':'Google','apple':'Apple','email':'Email and password'}.get(context.get('provider'),'Google' if context.get('preview') else 'A sign-in method')
    substitutions={'app_name':BRAND['name'],'display_name':name,'provider':provider}
    def interpolate(text):
        # One pass: user data containing placeholder syntax is never evaluated again.
        return re.sub(r'\{\{(app_name|display_name|provider)\}\}',lambda m:substitutions[m[1]],text)
    subject=interpolate(value['subject']);body=interpolate(value['body'])
    action_url=_action_url(identity,key,action_url)
    environment=identity.config['environment']
    label='' if environment=='production' else '['+environment.upper()+'] '
    action_label=ACTIONS[key][0] if key in ACTIONS else None
    note=NOTES[key]
    preheader=' '.join(body.split('\n\n')[1:]).replace('\n',' ')[:160] or subject
    year=datetime.fromtimestamp(identity.now(),timezone.utc).year
    markup=render_html(BRAND,title=subject,body=body,preheader=preheader,label=LABELS[key],
                       action_url=action_url,action_label=action_label,security_note=note,environment=environment,year=year)
    text=BRAND['name']+' — '+BRAND['tagline']+'\n\n'+subject+'\n\n'+body
    if action_url:text+='\n\n'+action_label+':\n'+action_url
    text+='\n\n'+note+'\n\n'+BRAND['footer']+'\n'+BRAND['name']+' · Account email · '+str(year)+'\nContact: '+BRAND['contact_email']+'\n'+BRAND['name']+' will never ask for your password by email.'
    return dict(subject=label+BRAND['name']+' — '+subject,text=text,html=markup)
