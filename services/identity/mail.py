"""Leased SMTP outbox worker. Never logs recipient, payload, password or action token."""
import html
import json
import smtplib
import ssl
from email.message import EmailMessage
from email.utils import formataddr, parseaddr
from urllib.parse import quote
from .core import AuthError

TEMPLATES={
 'email-verification':('Confirm your email','Confirm your email address to activate your account.'),
 'welcome':('Welcome','Your account is ready. You can now sign in to the app.'),
 'password-reset':('Reset your password','Use this link to choose a new password. It expires in one hour.'),
 'password-changed':('Password changed','Your password was changed. If this was not you, contact support.'),
 'security-alert':('Account security alert','An important security change occurred on your account.'),
}


def message(identity,row):
    payload=json.loads(identity.cipher.decrypt(row['payload_encrypted'].encode()))
    title,body=TEMPLATES[row['template']]
    brand={'statz':'STATZ','bliss':'Bliss','sixth':'Sixth','split':'Split Paper'}[identity.product]
    url=identity.config['public_url'].rstrip('/')
    action_url=None
    if row['template'] in ('email-verification','password-reset'):
        # Fragment keeps bearer token out of proxy/access logs and Referer headers.
        url += '/action#purpose='+payload['purpose']+'&token='+quote(payload['token'],safe='')
        action_url=url
        body += '\n\n'+url
    msg=EmailMessage()
    label='' if identity.config['environment']=='production' else '['+identity.config['environment'].upper()+'] '
    msg['Subject']=label+brand+' — '+title
    msg['From']=formataddr((brand, parseaddr(identity.config['smtp_from'])[1]))
    if identity.config.get('smtp_reply_to'):
        msg['Reply-To']=identity.config['smtp_reply_to']
    msg['To']=row['recipient']
    msg['Message-ID']='<'+row['id']+'@'+identity.config['message_domain']+'>'
    msg.set_content(brand+'\n\n'+body)
    html_body=html.escape(body).replace('\n','<br>')
    if action_url:
        escaped=html.escape(action_url,quote=True)
        html_body=html_body.replace(escaped,'<a href="'+escaped+'">'+html.escape(title)+'</a>')
    msg.add_alternative('<!doctype html><html><body><h1>'+html.escape(brand)+'</h1><h2>'+html.escape(title)+'</h2><p>'+html_body+'</p></body></html>',subtype='html')
    return msg


def deliver_one(identity,sender=None):
    if not identity.config.get('mail_enabled'):
        return False
    now=identity.now()
    with identity.engine.begin() as c:
        suffix=' FOR UPDATE SKIP LOCKED' if c.dialect.name=='mysql' else ''
        row=identity.one(c,"SELECT * FROM auth_email_outbox WHERE ((status='pending' AND next_attempt_at<=:n) OR (status='sending' AND lease_until<:n)) ORDER BY created_at LIMIT 1"+suffix,n=now)
        if not row:return False
        row=dict(row)
        identity.execute(c,"UPDATE auth_email_outbox SET status='sending',lease_until=:l,attempts=attempts+1 WHERE id=:i",l=now+120,i=row['id'])
    try:
        allowed=identity.config.get('mail_allowlist',[])
        if identity.config['environment']!='production' and row['recipient'].lower() not in allowed:
            raise AuthError('recipient_not_allowed')
        msg=message(identity,row)
        if sender:sender(msg)
        else:
            cfg=identity.config
            security=cfg.get('smtp_security','starttls')
            if security not in ('starttls','ssl'):raise AuthError('invalid_smtp_security')
            factory=smtplib.SMTP_SSL if security=='ssl' else smtplib.SMTP
            kwargs={'context':ssl.create_default_context()} if security=='ssl' else {}
            with factory(cfg['smtp_host'],int(cfg.get('smtp_port',587)),timeout=20,**kwargs) as smtp:
                if security=='starttls':smtp.starttls(context=ssl.create_default_context())
                smtp.login(cfg['smtp_user'],cfg['smtp_password'])
                smtp.send_message(msg, from_addr=parseaddr(cfg['smtp_from'])[1])
        with identity.engine.begin() as c:
            identity.execute(c,"UPDATE auth_email_outbox SET status='sent',sent_at=:n,lease_until=NULL,payload_encrypted='',error_code=NULL WHERE id=:i",n=identity.now(),i=row['id'])
    except Exception as error:
        code=error.code if isinstance(error,AuthError) else 'delivery_failed'
        attempts=row['attempts']+1
        with identity.engine.begin() as c:
            identity.execute(c,'UPDATE auth_email_outbox SET status=:s,next_attempt_at=:n,lease_until=NULL,error_code=:e WHERE id=:i',
                s='failed' if attempts>=5 or code=='recipient_not_allowed' else 'pending',n=identity.now()+min(3600,60*2**attempts),e=code,i=row['id'])
    return True
