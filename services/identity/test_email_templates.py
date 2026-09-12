"""Branded mail and transactional trigger regressions. No SMTP/network delivery."""
import json
import os
import secrets
import unittest
from html.parser import HTMLParser
from unittest.mock import patch
from flask import Flask
from . import test_identity, templates
from .admin_api import blueprint
from .core import AuthError
from .email_brand import BRAND
from .mail import message, deliver_one

KEYS = {'welcome', 'email-verification', 'password-reset', 'password-changed', 'identity-linked', 'security-alert'}

class Markup(HTMLParser):
    def __init__(self, source):
        super().__init__(); self.links=[]; self.tags=[]; self.content=[]; self.feed(source)
    def handle_starttag(self, tag, attrs):
        self.tags.append(tag)
        if tag=='a': self.links.append(dict(attrs).get('href'))
        assert not any(name.lower().startswith('on') for name, _ in attrs)
    def handle_data(self, data): self.content.append(data)

class EmailTemplateTest(unittest.TestCase):
    def setUp(self):
        self.f=test_identity.IdentityTest(); self.f.setUp(); self.addCleanup(self.f.tearDown)
        self.i=self.f.identity
        for target in ('services.identity.mail.smtplib.SMTP','services.identity.mail.smtplib.SMTP_SSL'):
            guard=patch(target,side_effect=AssertionError('Real SMTP forbidden in tests'))
            guard.start(); self.addCleanup(guard.stop)
        app=Flask(__name__); self.prefix='/api/admin/v1/'+self.i.product
        app.register_blueprint(blueprint(self.i),url_prefix=self.prefix); self.client=app.test_client()
        env=patch.dict(os.environ,{self.i.product.upper()+'_ADMIN_READ_TOKEN':'r'*40})
        env.start(); self.addCleanup(env.stop)
        self.headers={'Authorization':'Bearer '+'r'*40}
    def rows(self, template=None):
        with self.i.engine.connect() as c:
            return [dict(r) for r in self.i.execute(c,'SELECT * FROM auth_email_outbox'+(' WHERE template=:t' if template else ''),t=template).mappings()]
    def payload(self, row): return json.loads(self.i.cipher.decrypt(row['payload_encrypted'].encode()))
    def social_account(self): return self.i.social('google','original',None,None,'ip')['user']['id']
    def link(self, uid, provider='google', subject='new-identity'):
        self.i.verifier=lambda *a:dict(sub=subject,email='user@example.com',email_verified=True)
        nonce=self.i.challenge('ip')['nonce'] if provider=='apple' else None
        return self.i.social(provider,subject,nonce,None,'ip',link_user=uid)

    def test_six_branded_responsive_templates_with_plain_text(self):
        self.assertEqual(set(templates.TEMPLATES),KEYS)
        self.assertEqual(BRAND['product'],self.i.product)
        for key in KEYS:
            with self.subTest(key=key):
                action='https://preview.invalid/confirmation' if key in templates.ACTIONS else None
                rendered=templates.render(self.i,key,action_url=action,context={'display_name':'Alex','provider':'apple'})
                self.assertIn(BRAND['wordmark'],rendered['html']); self.assertIn(BRAND['name'],rendered['text'])
                self.assertIn('Alex',rendered['text']); self.assertNotIn('{{',rendered['text'])
                self.assertIn('viewport',rendered['html']); self.assertIn('@media',rendered['html'])
                self.assertIn('max-width:600px',rendered['html']); self.assertIn('<!--[if mso]>',rendered['html'])
                self.assertLess(len(rendered['html'].encode()),40000)
                markup=Markup(rendered['html'])
                self.assertFalse({'script','iframe','form','img','link'} & set(markup.tags))
                self.assertEqual(markup.links,([action,action] if action else [])+['mailto:'+BRAND['contact_email']])
                self.assertIn('[TEST]',rendered['subject'])
                self.assertEqual(templates.get(self.i,key)['automatically_triggered'],key!='security-alert')
    def test_user_data_escaped_and_not_reinterpolated_or_put_in_headers(self):
        name='<img src=x onerror="bad()"> & {{app_name}}\r\nBcc: x@example.invalid'
        value={'subject':'Hello {{display_name}}','body':'Hi {{display_name}}\n\n{{provider}} is connected.'}
        rendered=templates.render(self.i,'identity-linked',value,context={'display_name':name,'provider':'<script>'})
        self.assertNotIn('<img',rendered['html']); self.assertIn('&lt;img',rendered['html'])
        self.assertIn('{{app_name}}',rendered['text']); self.assertNotIn('\n',rendered['subject']); self.assertNotIn('\r',rendered['subject'])
        self.assertIn('A sign-in method',rendered['text']); Markup(rendered['html'])
    def test_only_backend_controls_action_links(self):
        token=secrets.token_urlsafe(32)
        base=self.i.config['public_url']+'/action'
        good=base+'#purpose=verify&token='+token
        markup=templates.render(self.i,'email-verification',action_url=good)['html']
        parsed=Markup(markup); self.assertEqual(parsed.links,[good,good,'mailto:'+BRAND['contact_email']])
        self.assertEqual(''.join(parsed.content).count(token),1)
        bad=['javascript:alert(1)','https://outside.invalid/#purpose=verify&token='+token,
             base+'?token='+token,base+'#purpose=reset&token='+token,
             good+'&redirect=https://outside.invalid',good+'&token='+token]
        for url in bad:
            with self.assertRaises(AuthError):templates.render(self.i,'email-verification',action_url=url)
        with self.assertRaises(AuthError):templates.render(self.i,'welcome',action_url=good)
        for body in ('{{token}}','{{password}}','{{action_url}}','{{provider}}'):
            with self.assertRaises(AuthError):templates.validate('welcome',{'subject':'Welcome','body':body})
    def test_preview_has_invalid_links_no_tokens_and_never_enqueues_or_sends(self):
        self.f.register(); before=self.rows()
        with patch('services.identity.mail.deliver_one',side_effect=AssertionError('No preview sends')):
            for key in KEYS:
                reply=self.client.post(self.prefix+'/email-templates/'+key+'/preview',json={},headers=self.headers)
                self.assertEqual(reply.status_code,200,reply.json); self.assertFalse(reply.json['sends_email'])
                markup=Markup(reply.json['preview']['html'])
                self.assertEqual(markup.links,(['https://preview.invalid/confirmation']*2 if key in templates.ACTIONS else [])+['mailto:'+BRAND['contact_email']])
                self.assertNotIn('token=',reply.text); self.assertNotIn('payload_encrypted',reply.text)
        self.assertEqual(self.rows(),before)
    def test_brand_wraps_saved_copy_without_overwriting_revisions_or_history(self):
        data=dict(subject='For {{display_name}}',body='{{provider}} connected to {{app_name}}. <b>Plain copy</b>',expected_revision=0,actor='test-admin')
        saved=templates.save(self.i,'identity-linked',data); self.assertEqual(saved['revision'],1)
        rendered=templates.render(self.i,'identity-linked',context={'display_name':'Alex','provider':'apple'})
        self.assertIn('Apple connected to '+BRAND['name'],rendered['text']); self.assertIn('&lt;b&gt;',rendered['html'])
        self.assertIn(BRAND['wordmark'],rendered['html'])
        with self.assertRaises(AuthError):templates.save(self.i,'identity-linked',data)
        with self.i.engine.connect() as c:
            self.assertEqual(self.i.one(c,'SELECT COUNT(*) n FROM auth_template_revisions')['n'],1)
    def test_worker_uses_brand_and_user_context_only(self):
        self.f.register(); row=self.rows('email-verification')[0]
        p=self.payload(row); p.update(password='do-not-render-this',api_key='never-render-either',action_url='https://evil.invalid')
        row['payload_encrypted']=self.i.cipher.encrypt(json.dumps(p).encode()).decode()
        msg=message(self.i,row); self.assertEqual(msg.get_content_type(),'multipart/alternative')
        markup=msg.get_body(preferencelist=('html',)).get_content(); plain=msg.get_body(preferencelist=('plain',)).get_content()
        self.assertIn('Test',plain); self.assertIn(BRAND['wordmark'],markup)
        for forbidden in ('do-not-render-this','never-render-either','evil.invalid'):
            self.assertNotIn(forbidden,msg.as_string())
        self.assertEqual(''.join(Markup(markup).content).count(p['token']),1)
    def test_email_registration_welcome_only_after_confirmation_once(self):
        self.f.register(); self.assertEqual([r['template'] for r in self.rows()],['email-verification'])
        token=self.f.action(); self.i.consume(token,'verify')
        self.assertEqual(len(self.rows('welcome')),1); self.assertEqual(self.rows('identity-linked'),[])
        with self.assertRaises(AuthError):self.i.consume(token,'verify')
        self.assertEqual(len(self.rows('welcome')),1)
    def test_social_registration_and_relogin_do_not_mean_identity_linked(self):
        self.social_account(); self.social_account()
        self.assertEqual(len(self.rows('welcome')),1); self.assertEqual(self.rows('identity-linked'),[])
    def test_google_link_notifies_once_to_verified_account_contact(self):
        uid=self.f.verified()['user']['id']; self.link(uid); self.link(uid)
        rows=self.rows('identity-linked'); self.assertEqual(len(rows),1)
        self.assertEqual(rows[0]['recipient'],'user@example.com'); self.assertEqual(self.payload(rows[0]),{'provider':'google'})
        self.assertNotIn('new-identity',rows[0]['dedupe_key'])
        with self.i.engine.connect() as c:
            self.assertEqual(self.i.one(c,"SELECT COUNT(*) n FROM auth_security_events WHERE event_type='provider_linked'")['n'],1)
    def test_apple_link_requires_nonce_and_notifies_once(self):
        uid=self.f.verified()['user']['id']; self.link(uid,'apple'); self.link(uid,'apple')
        self.assertEqual(len(self.rows('identity-linked')),1); self.assertEqual(self.payload(self.rows('identity-linked')[0]),{'provider':'apple'})
        with self.assertRaises(AuthError):self.i.social('apple','new-identity',None,None,'ip',link_user=uid)
        self.assertEqual(len(self.rows('identity-linked')),1)
    def test_email_link_notifies_only_after_confirmation_not_request(self):
        uid=self.social_account(); self.i.link_email(uid,'another@example.com','a strong password!','ip')
        self.assertEqual(self.rows('identity-linked'),[])
        token=self.f.action(); self.i.consume(token,'verify')
        rows=self.rows('identity-linked'); self.assertEqual(len(rows),1)
        self.assertEqual(rows[0]['recipient'],'social@example.com'); self.assertEqual(self.payload(rows[0]),{'provider':'email'})
        self.assertEqual(len(self.rows('welcome')),1)
        with self.assertRaises(AuthError):self.i.consume(token,'verify')
        self.assertEqual(len(self.rows('identity-linked')),1)
    def test_failed_ownership_or_provider_proof_never_notifies(self):
        other=self.social_account(); uid=self.f.verified()['user']['id']
        with self.assertRaises(AuthError):self.i.social('google','original',None,None,'ip',link_user=uid)
        self.i.verifier=lambda *a:dict(sub='bad',email='user@example.com',email_verified=False)
        with self.assertRaises(AuthError):self.i.social('google','bad',None,None,'ip',link_user=uid)
        self.assertEqual(self.rows('identity-linked'),[])
    def test_expired_email_link_never_notifies_or_creates_password(self):
        uid=self.social_account(); self.i.link_email(uid,'another@example.com','a strong password!','ip')
        with self.i.engine.begin() as c:self.i.execute(c,'UPDATE auth_actions SET expires_at=0')
        with self.assertRaises(AuthError):self.i.consume(self.f.action(),'verify')
        self.assertEqual(self.rows('identity-linked'),[]); self.assertFalse(self.i.methods(uid)['password_enabled'])
    def test_failed_transaction_rolls_back_identity_and_notification(self):
        uid=self.f.verified()['user']['id']; original=self.i.enqueue
        def fail_after_insert(*args,**kwargs):
            original(*args,**kwargs); raise RuntimeError('Simulated transaction failure')
        with patch.object(self.i,'enqueue',side_effect=fail_after_insert):
            with self.assertRaises(RuntimeError):self.link(uid)
        self.assertEqual(self.i.methods(uid)['providers'],[]); self.assertEqual(self.rows('identity-linked'),[])
        self.link(uid); self.assertEqual(len(self.rows('identity-linked')),1)
    def test_no_notification_to_unverified_contact(self):
        self.i.verifier=lambda *a:dict(sub='apple-only')
        uid=self.i.social('apple','token',self.i.challenge('ip')['nonce'],None,'ip')['user']['id']
        with self.i.engine.begin() as c:
            self.i.execute(c,"INSERT INTO auth_email_addresses(user_id,email,verification_source) VALUES(:u,:e,'email')",u=uid,e='unverified@example.com')
        self.i.verifier=lambda *a:dict(sub='second-apple')
        self.i.social('apple','token',self.i.challenge('ip')['nonce'],None,'ip',link_user=uid)
        self.assertEqual(self.rows('identity-linked'),[])
    def test_reset_confirmation_and_no_security_alert_on_auth_events(self):
        session=self.f.verified(); self.i.request_email('missing@example.com','reset','ip')
        self.assertEqual(self.rows('password-reset'),[])
        self.i.request_email('user@example.com','reset','ip'); self.assertEqual(self.rows('password-changed'),[])
        token=self.payload(self.rows('password-reset')[0])['token']
        self.i.consume(token,'reset','a different password!'); self.assertEqual(len(self.rows('password-changed')),1)
        with self.assertRaises(AuthError):self.i.consume(token,'reset','a different password!')
        with self.assertRaises(AuthError):self.i.authenticate(session['access_token'])
        self.link(session['user']['id']); self.assertEqual(self.rows('security-alert'),[])
    def test_mock_delivery_clears_encrypted_payload_and_sanitizes_failures(self):
        self.f.register(); messages=[]; deliver_one(self.i,messages.append)
        self.assertEqual(len(messages),1); self.assertEqual(self.rows()[0]['payload_encrypted'],'')
        self.assertEqual(self.rows()[0]['status'],'sent')

    def test_action_fallback_visible_clickable_and_plain_url_unchanged(self):
        for key,purpose in [('email-verification','verify'),('password-reset','reset')]:
            url=self.i.config['public_url']+'/action#purpose='+purpose+'&token='+secrets.token_urlsafe(80)
            rendered=templates.render(self.i,key,action_url=url)
            markup=Markup(rendered['html'])
            self.assertEqual(markup.links[:2],[url,url])
            self.assertIn('If the button does not work, copy and paste this link:',''.join(markup.content))
            self.assertEqual(''.join(markup.content).count(url),1)
            self.assertIn(url,rendered['text'])
            self.assertIn('word-break:break-all',rendered['html']);self.assertIn('table-layout:fixed',rendered['html'])
        for key in KEYS-{'email-verification','password-reset'}:
            rendered=templates.render(self.i,key)
            self.assertNotIn('If the button does not work',rendered['html'])
            self.assertEqual(Markup(rendered['html']).links,['mailto:'+BRAND['contact_email']])

    def test_contact_footer_current_year_and_transactional_headers(self):
        from datetime import datetime,timezone
        from email.utils import parseaddr
        self.f.register();row=self.rows('email-verification')[0]
        self.i.config.update(smtp_from='contact@dddcreate.com',smtp_reply_to=BRAND['contact_email'])
        msg=message(self.i,row)
        self.assertEqual(parseaddr(msg['From']),(BRAND['name'],'contact@dddcreate.com'))
        self.assertEqual(parseaddr(msg['Reply-To']),(BRAND['name'],BRAND['contact_email']))
        for year in [2026,2031]:
            self.i.clock=lambda:datetime(year,1,1,tzinfo=timezone.utc).timestamp()
            for key in KEYS:
                result=templates.render(self.i,key)
                self.assertIn(BRAND['name']+' · Account email · '+str(year),result['html'])
                self.assertIn('mailto:'+BRAND['contact_email'],Markup(result['html']).links)
                self.assertIn(BRAND['contact_email'],result['text']);self.assertIn(str(year),result['text'])
                for content in [result['html'],result['text']]:
                    self.assertIn('will never ask for your password by email.',content)
                    self.assertNotIn('unsubscribe',content.lower());self.assertNotIn('newsletter',content.lower())
        for environment in ['test','development','staging']:
            self.i.config['environment']=environment
            result=templates.render(self.i,'welcome')
            self.assertIn('['+environment.upper()+']',result['subject']);self.assertIn(environment.upper(),result['html'])
        self.i.config['environment']='production'
        self.assertFalse(templates.render(self.i,'welcome')['subject'].startswith('['))
        self.i.config.pop('smtp_reply_to',None)
        self.assertEqual(parseaddr(message(self.i,row)['Reply-To']),(BRAND['name'],BRAND['contact_email']))

    def preview(self,key,data):
        return self.client.post(self.prefix+'/email-templates/'+key+'/preview',json=data,headers=self.headers)

    def test_preview_context_only_and_copy_override_leave_database_unchanged(self):
        templates.save(self.i,'identity-linked',dict(subject='Linked {{provider}}',body='Hello {{display_name}}. {{provider}} is ready.',expected_revision=0,actor='test-admin'))
        before=templates.get(self.i,'identity-linked');self.f.register();outbox=self.rows()
        for provider,label in [('google','Google'),('apple','Apple'),('email','Email and password')]:
            for use_override in [False,True]:
                data={'context':{'display_name':'<b>Alex & {{app_name}}</b>','provider':provider}}
                if use_override:data.update(subject='Preview {{provider}}',body='{{display_name}} / {{provider}}')
                response=self.preview('identity-linked',data)
                self.assertEqual(response.status_code,200,response.json);self.assertFalse(response.json['sends_email'])
                result=response.json['preview']
                self.assertIn(label,result['subject']);self.assertIn(label,result['text'])
                self.assertIn('&lt;b&gt;Alex &amp; {{app_name}}&lt;/b&gt;',result['html']);self.assertNotIn('<b>Alex',result['html'])
                self.assertEqual(templates.get(self.i,'identity-linked'),before)
        self.assertEqual(self.rows(),outbox)
        with self.i.engine.connect() as c:
            self.assertEqual(self.i.one(c,'SELECT COUNT(*) n FROM auth_template_revisions')['n'],1)
        # Existing clients remain compatible with {} and subject/body only.
        self.assertEqual(self.preview('welcome',{}).status_code,200)
        self.assertEqual(self.preview('welcome',{'subject':'Hi','body':'Old client preview'}).status_code,200)
        self.assertEqual(self.preview('welcome',{'context':{}}).status_code,200)

    def test_preview_rejects_unknown_fields_types_controls_and_oversize(self):
        contexts=[None,[],True,'Alex',{'token':'x'},{'preview':True},{'recipient':'outside@example.com'},
                  {'display_name':None},{'display_name':3},{'display_name':''},{'display_name':'  '},
                  {'display_name':'A'*121},{'display_name':'Alex\r\nBcc: evil'},{'display_name':'A\x00B'},
                  {'display_name':'A\x7fB'},{'provider':'Google'},{'provider':'github'},
                  {'provider':['google']},{'provider':None}]
        for context in contexts:
            with self.subTest(context=context):self.assertEqual(self.preview('welcome',{'context':context}).status_code,400)
        for key in ['token','recipient','action_url','environment','year','expected_revision','actor']:
            self.assertEqual(self.preview('welcome',{key:'forbidden'}).status_code,400)
        self.assertEqual(self.preview('welcome',{'subject':'Missing body','context':{}}).status_code,400)
        self.assertEqual(self.rows(),[])
        with self.i.engine.connect() as c:
            self.assertEqual(self.i.one(c,'SELECT COUNT(*) n FROM auth_email_templates')['n'],0)
            self.assertEqual(self.i.one(c,'SELECT COUNT(*) n FROM auth_template_revisions')['n'],0)

    def _assert_link_path(self,path):
        email='user@example.com'
        self.i.verifier=lambda provider,token,nonce:dict(sub=token,email=email,email_verified=True)
        def social(provider,uid=None):
            nonce=self.i.challenge('matrix-ip')['nonce'] if provider=='apple' else None
            return self.i.social(provider,'matrix-'+provider,nonce,None,'matrix-ip',link_user=uid)
        if path[0]=='email':
            uid=self.f.verified()['user']['id']
        else:uid=social(path[0])['user']['id']
        self.assertEqual(len(self.rows('welcome')),1);self.assertEqual(self.rows('identity-linked'),[])
        labels={'google':'Google','apple':'Apple','email':'Email and password'}
        for count,provider in enumerate(path[1:],1):
            if provider=='email':
                self.i.link_email(uid,email,'a strong password!','matrix-ip')
                self.assertEqual(len(self.rows('identity-linked')),count-1)
                with self.i.engine.connect() as c:
                    pending=self.i.one(c,"SELECT payload_encrypted FROM auth_email_outbox WHERE template='email-verification' AND status='pending'")
                token=json.loads(self.i.cipher.decrypt(pending['payload_encrypted'].encode()))['token']
                self.i.consume(token,'verify')
                with self.assertRaises(AuthError):self.i.consume(token,'verify')
                with self.assertRaises(AuthError):self.i.link_email(uid,email,'a strong password!','matrix-ip')
            else:
                social(provider,uid);social(provider,uid)
            linked=self.rows('identity-linked');self.assertEqual(len(linked),count)
            current=[r for r in linked if self.payload(r)['provider']==provider]
            self.assertEqual(len(current),1)
            msg=message(self.i,current[0])
            self.assertIn(labels[provider],msg['Subject']);self.assertIn(labels[provider],msg.get_body(preferencelist=('plain',)).get_content())
            self.assertEqual(len(self.rows('welcome')),1)
            self.assertEqual(self.f.row('SELECT COUNT(*) n FROM app_users')['n'],1)
        self.assertEqual(set(self.i.methods(uid)['providers']),{'google','apple'})
        self.assertTrue(self.i.methods(uid)['password_enabled'])
        self.assertEqual(self.rows('security-alert'),[])
        messages=[]
        for _ in range(len(self.rows())):deliver_one(self.i,messages.append)
        self.assertEqual(sum(labels[path[-1]] in m['Subject'] for m in messages),1)
        self.assertTrue(all(r['status']=='sent' for r in self.rows()))

    def test_link_path_google_apple_email(self):self._assert_link_path(('google','apple','email'))
    def test_link_path_google_email_apple(self):self._assert_link_path(('google','email','apple'))
    def test_link_path_apple_google_email(self):self._assert_link_path(('apple','google','email'))
    def test_link_path_apple_email_google(self):self._assert_link_path(('apple','email','google'))
    def test_link_path_email_google_apple(self):self._assert_link_path(('email','google','apple'))
    def test_link_path_email_apple_google(self):self._assert_link_path(('email','apple','google'))

    def test_apple_without_original_email_adds_password_without_a_late_welcome(self):
        self.i.verifier=lambda *args:dict(sub='apple-no-email')
        uid=self.i.social('apple','token',self.i.challenge('ip')['nonce'],None,'ip')['user']['id']
        self.assertEqual(self.rows(),[])
        self.i.link_email(uid,'user@example.com','a strong password!','ip')
        self.i.consume(self.f.action(),'verify')
        self.assertEqual(self.rows('welcome'),[])
        self.assertEqual(len(self.rows('identity-linked')),1)
        row=self.rows('identity-linked')[0]
        self.assertEqual(row['recipient'],'user@example.com');self.assertEqual(self.payload(row),{'provider':'email'})
        self.assertEqual(self.rows('security-alert'),[])

if __name__=='__main__': unittest.main()
