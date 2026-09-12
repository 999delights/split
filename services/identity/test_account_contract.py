import json
import os
import unittest
from unittest.mock import patch
from flask import Flask
from sqlalchemy import text
from . import test_identity,templates
from .core import AuthError
from .admin_api import blueprint
from .http_api import blueprint as auth_blueprint
from .mail import deliver_one

DEVICE=dict(id='a1b2c3d4-1111-4222-8333-123456789abc',platform='ios',name='iPhone',model='iPhone16,1',app_version='1.0.0+1')

class AccountContractTest(unittest.TestCase):
 def setUp(self):
  self.f=test_identity.IdentityTest();self.f.setUp();self.addCleanup(self.f.tearDown)
  self.i=self.f.identity
  if self.i.product=='bliss':
   with self.i.engine.begin() as c:self.i.execute(c,'CREATE TABLE agents(id TEXT,owner_user_id TEXT,name TEXT,version TEXT,created_at TEXT,last_seen_at TEXT,revoked_at TEXT)')
  app=Flask(__name__);self.prefix='/api/admin/v1/'+self.i.product
  app.register_blueprint(blueprint(self.i),url_prefix=self.prefix);app.register_blueprint(auth_blueprint(self.i),url_prefix='/api/auth')
  self.client=app.test_client()
  self.read={'Authorization':'Bearer '+'r'*40};self.write={'Authorization':'Bearer '+'w'*40}
  env=patch.dict(os.environ,{self.i.product.upper()+'_ADMIN_READ_TOKEN':'r'*40,self.i.product.upper()+'_ADMIN_WRITE_TOKEN':'w'*40});env.start();self.addCleanup(env.stop)
 def api(self,path,method='GET',data=None,headers=None):
  return self.client.open(self.prefix+path,method=method,json=data,headers=headers or self.read)
 def token(self):
  with self.i.engine.connect() as c:r=self.i.one(c,"SELECT payload_encrypted FROM auth_email_outbox WHERE template='email-verification' ORDER BY created_at DESC,id DESC LIMIT 1")
  return json.loads(self.i.cipher.decrypt(r['payload_encrypted'].encode()))['token']
 def test_user_tokens_and_other_product_admin_tokens_rejected(self):
  s=self.f.verified()
  self.assertEqual(self.api('/users',headers={'Authorization':'Bearer '+s['access_token']}).status_code,401)
  self.assertEqual(self.client.get(self.prefix+'/users').status_code,401)
  with patch.dict(os.environ,{self.i.product.upper()+'_ADMIN_READ_TOKEN':''}):self.assertEqual(self.api('/users').status_code,401)
 def test_linking_requires_proof_and_no_duplicate_users(self):
  s=self.f.verified();uid=s['user']['id']
  self.i.verifier=lambda p,t,n:dict(sub=t,email='user@example.com',email_verified=True)
  with self.assertRaises(AuthError):self.i.social('google','subject',None,DEVICE,'ip')
  self.i.social('google','subject',None,None,'ip',link_user=uid)
  self.i.social('google','subject',None,None,'ip',link_user=uid)
  self.assertEqual(self.f.row('SELECT COUNT(*) n FROM app_users')['n'],1)
  self.assertEqual(self.i.social('google','subject',None,DEVICE,'ip')['user']['id'],uid)
  methods=self.i.methods(uid);self.assertEqual(methods['providers'],['google']);self.assertTrue(methods['password_enabled'])
  with self.assertRaises(AuthError):self.i.social('google','subject',None,None,'ip',link_user='another')
 def test_google_to_email_requires_separate_confirmation(self):
  s=self.i.social('google','subject',None,DEVICE,'ip');uid=s['user']['id']
  self.i.link_email(uid,'social@example.com','a strong password!','ip')
  self.assertFalse(self.i.methods(uid)['password_enabled'])
  self.assertIsNone(self.f.row('SELECT confirmed_at FROM auth_email_addresses')['confirmed_at'])
  self.i.consume(self.token(),'verify')
  self.assertIsNotNone(self.f.row('SELECT confirmed_at FROM auth_email_addresses')['confirmed_at'])
  self.assertEqual(self.i.login('social@example.com','a strong password!',DEVICE,'ip')['user']['id'],uid)
  self.assertIsNone(self.f.row('SELECT pending_password_hash FROM auth_actions')['pending_password_hash'])
  self.assertEqual(self.f.row("SELECT COUNT(*) n FROM auth_email_outbox WHERE template='welcome'")['n'],1)
 def test_apple_relay_email_can_be_linked_but_not_stolen(self):
  a=self.f.verified();uid=a['user']['id']
  self.i.verifier=lambda p,t,n:dict(sub=t,email='relay@example.com',email_verified=True)
  nonce=self.i.challenge('ip')['nonce'];self.i.social('apple','apple-sub',nonce,None,'ip',link_user=uid)
  self.assertEqual(self.i.methods(uid)['providers'],['apple'])
  with self.assertRaises(AuthError):self.i.social('apple','apple-sub',nonce,None,'ip',link_user=uid)
  nonce=self.i.challenge('ip')['nonce']
  with self.assertRaises(AuthError):self.i.social('apple','apple-sub',nonce,None,'ip',link_user='another')
 def test_unverified_google_rejected(self):
  self.i.verifier=lambda *a:dict(sub='a',email='user@example.com',email_verified=False)
  with self.assertRaises(AuthError):self.i.social('google','token',None,DEVICE,'ip')
 def test_rotation_is_one_session_and_one_device(self):
  s=self.i.social('google','subject',None,DEVICE,'ip');uid=s['user']['id']
  refreshed=self.i.refresh(s['refresh_token'],DEVICE)
  r=self.api('/users/'+uid);self.assertEqual(r.status_code,200,r.json)
  user=r.json['user'];self.assertEqual(user['active_sessions'],1);self.assertEqual(len(user['sessions']),1);self.assertEqual(len(user['devices']),1)
  self.assertEqual(user['devices'][0]['platform'],'ios');self.assertEqual(user['sessions'][0]['status'],'active')
  self.assertTrue(user['last_login_at'].endswith('Z'));self.assertEqual(user['email_addresses'][0]['confirmed_at'],None)
  for value in (s['access_token'],s['refresh_token'],'token_hash','password_hash','payload_encrypted','installation_id'):self.assertNotIn(value,r.text)
  self.i.logout(uid,refreshed['refresh_token']);user=self.api('/users/'+uid).json['user']
  self.assertEqual(user['active_sessions'],0);self.assertEqual(user['sessions'][0]['status'],'revoked')
 def test_old_session_device_enrichment_and_mismatch_rollback(self):
  s=self.f.verified();uid=s['user']['id'];r=self.i.refresh(s['refresh_token'],DEVICE)
  self.assertEqual(self.api('/users/'+uid).json['user']['devices'][0]['model'],'iPhone16,1')
  with self.assertRaises(AuthError):self.i.refresh(r['refresh_token'],{**DEVICE,'id':'b1b2c3d4-1111-4222-8333-123456789abc'})
  self.assertEqual(self.f.row('SELECT COUNT(*) n FROM user_devices')['n'],1)
  self.i.refresh(r['refresh_token'],DEVICE)
 def test_expired_and_disabled_sessions_not_active(self):
  s=self.f.verified();uid=s['user']['id']
  with self.i.engine.begin() as c:self.i.execute(c,'UPDATE auth_sessions SET expires_at=0')
  u=self.api('/users/'+uid).json['user'];self.assertEqual(u['active_sessions'],0);self.assertEqual(u['sessions'][0]['status'],'expired')
 def test_templates_scopes_revision_preview_and_delivery(self):
  items=self.api('/email-templates').json['templates'];self.assertEqual(len(items),6)
  self.assertFalse(next(x for x in items if x['key']=='security-alert')['automatically_triggered'])
  data=dict(subject='Hello {{app_name}}',body='A <b>safe</b> welcome',expected_revision=0,actor='admin-test')
  self.assertEqual(self.api('/email-templates/welcome','PATCH',data).status_code,401)
  result=self.api('/email-templates/welcome','PATCH',data,self.write);self.assertEqual(result.status_code,200,result.json)
  self.assertEqual(result.json['template']['revision'],1)
  self.assertEqual(self.api('/email-templates/welcome','PATCH',data,self.write).status_code,409)
  preview=self.api('/email-templates/welcome/preview','POST',{}).json['preview'];self.assertIn('&lt;b&gt;',preview['html'])
  s=self.f.verified();sent=[]
  for _ in range(2):deliver_one(self.i,sent.append)
  welcome=next(m for m in sent if 'Hello' in m['Subject']);self.assertIn('safe',welcome.get_body(preferencelist=('plain',)).get_content())
  data['expected_revision']=1;data['subject']='Bad\r\nBcc: outside@example.com'
  self.assertEqual(self.api('/email-templates/welcome','PATCH',data,self.write).status_code,400)
  self.assertNotIn('payload_encrypted',self.api('/email-outbox').text)
  self.assertNotIn('token=',self.api('/email-outbox').text)
 def test_preview_keeps_action_link_managed_and_rejects_unknown_variables(self):
  good=dict(subject='Verify',body='{{app_name}} confirmation')
  result=self.api('/email-templates/email-verification/preview','POST',good)
  self.assertEqual(result.status_code,200);self.assertIn('preview.invalid',result.json['preview']['html']);self.assertFalse(result.json['sends_email'])
  good['body']='{{token}}';self.assertEqual(self.api('/email-templates/welcome/preview','POST',good).status_code,400)
 def test_unknown_user_pagination_and_pending_outbox(self):
  self.assertEqual(self.api('/users/unknown').status_code,404)
  self.assertEqual(self.api('/users?limit=0').status_code,400)
  self.f.register();self.assertEqual(self.api('/email-outbox').json['messages'][0]['status'],'pending')
  self.assertEqual(self.api('/users').json['users'][0]['email_verified'],False)

 def test_linked_provider_verification_does_not_fabricate_email_confirmation(self):
  self.f.register()
  with self.i.engine.connect() as c:
   uid=self.i.one(c,'SELECT user_id FROM auth_email_addresses')['user_id']
  self.i.verifier=lambda *a:dict(sub='linked',email='user@example.com',email_verified=True)
  self.i.social('google','linked',None,None,'ip',link_user=uid)
  user=self.api('/users/'+uid).json['user']
  self.assertTrue(user['email_verified']);self.assertIsNone(user['email_confirmed_at'])
  self.assertEqual(user['login_methods'],['google','email'])

 def test_login_provider_not_overwritten_by_old_session_refresh(self):
  s=self.f.verified();uid=s['user']['id']
  self.i.verifier=lambda *a:dict(sub='g',email='user@example.com',email_verified=True)
  self.i.social('google','g',None,None,'ip',link_user=uid)
  self.i.social('google','g',None,DEVICE,'ip')
  self.i.refresh(s['refresh_token'])
  self.assertEqual(self.api('/users/'+uid).json['user']['last_login_provider'],'google')
