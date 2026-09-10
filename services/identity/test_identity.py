import json
import re
import unittest
from pathlib import Path
from cryptography.fernet import Fernet
from sqlalchemy import create_engine,text
from .core import Identity,AuthError,digest
from .mail import deliver_one

class IdentityTest(unittest.TestCase):
 def setUp(self):
  self.engine=create_engine('sqlite://')
  self.config=dict(product='split',environment='test',secret='t'*64,email_key=Fernet.generate_key().decode(),
    public_url='http://localhost',mail_enabled=True,smtp_from='Sixth <test@example.com>',message_domain='example.com',mail_allowlist=['user@example.com'])
  self.identity=Identity(self.engine,self.config,verifier=lambda p,t,n:{'sub':t,'email':'social@example.com','email_verified':True})
  # Equivalent SQLite fixture for service behavior, not a production migration.
  migration=next((Path(__file__).resolve().parents[2]/'infra/db/migrations').glob('*_application_authentication.sql'))
  sql=migration.read_text()
  sql=sql[sql.index('CREATE TABLE auth_email_addresses'):]
  with self.engine.begin() as c:
   c.execute(text('CREATE TABLE app_users(id TEXT PRIMARY KEY,email TEXT,display_name TEXT,status TEXT)'))
   c.execute(text('CREATE TABLE auth_identities(id TEXT PRIMARY KEY,user_id TEXT,provider TEXT,subject TEXT,email TEXT,UNIQUE(provider,subject))'))
   for statement in sql.split(';'):
    if not statement.strip() or statement.strip().startswith('ALTER'):continue
    statement=re.sub(r'\) ENGINE=.*',')',statement,flags=re.S)
    statement=re.sub(r',?\s*(?:UNIQUE KEY \w+\(([^)]+)\)|INDEX \w+\([^)]+\))',lambda m:', UNIQUE('+m[1]+')' if m[1] else '',statement)
    statement=statement.replace('BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY','INTEGER PRIMARY KEY AUTOINCREMENT')
    c.execute(text(statement))
 def tearDown(self):self.engine.dispose()
 def row(self,sql):
  with self.engine.connect() as c:return c.execute(text(sql)).mappings().first()
 def register(self):return self.identity.register('user@example.com','a strong password!', 'Test', '127.0.0.1')
 def action(self):
  row=self.row("SELECT * FROM auth_email_outbox WHERE template='email-verification'")
  return json.loads(self.identity.cipher.decrypt(row['payload_encrypted'].encode()))['token']
 def verified(self):
  self.register();self.identity.consume(self.action(),'verify')
  return self.identity.login('user@example.com','a strong password!','test','127.0.0.1')
 def test_product_sender_and_reply_to(self):
  from email.utils import parseaddr
  self.identity.config.update(smtp_from='contact@example.com',smtp_reply_to='support@example.com')
  self.register();messages=[]
  deliver_one(self.identity,messages.append)
  self.assertEqual(parseaddr(messages[0]['From'])[1],'contact@example.com')
  self.assertEqual(parseaddr(messages[0]['From'])[0],{'statz':'STATZ','bliss':'Bliss','sixth':'Sixth','split':'Split Paper'}[self.identity.product])
  self.assertEqual(messages[0]['Reply-To'],'support@example.com')
  self.assertEqual(messages[0]['To'],'user@example.com')
 def test_disabled_mail_does_not_deliver_queued_messages(self):
  self.register();self.identity.config['mail_enabled']=False;messages=[]
  self.assertFalse(deliver_one(self.identity,messages.append))
  self.assertEqual(messages,[])
  self.assertEqual(self.row('SELECT status FROM auth_email_outbox')['status'],'pending')
 def test_registration_requires_verification(self):
  self.register()
  with self.assertRaises(AuthError) as e:self.identity.login('user@example.com','a strong password!','test','127.0.0.1')
  self.assertEqual(e.exception.code,'email_not_verified')
 def test_action_hash_encrypted_outbox_and_single_use(self):
  self.register();token=self.action()
  self.assertNotIn(token,str(self.row('SELECT * FROM auth_actions')))
  self.assertNotIn(token,str(self.row('SELECT * FROM auth_email_outbox')))
  self.identity.consume(token,'verify')
  with self.assertRaises(AuthError):self.identity.consume(token,'verify')
 def test_expired_action(self):
  self.register();token=self.action()
  with self.engine.begin() as c:c.execute(text('UPDATE auth_actions SET expires_at=0'))
  with self.assertRaises(AuthError):self.identity.consume(token,'verify')
 def test_rotation_replay_revokes_family(self):
  old=self.verified();new=self.identity.refresh(old['refresh_token'])
  self.identity.authenticate(new['access_token'])
  with self.assertRaises(AuthError):self.identity.refresh(old['refresh_token'])
  with self.assertRaises(AuthError):self.identity.authenticate(new['access_token'])
 def test_logout_all(self):
  session=self.verified();uid=session['user']['id']
  self.identity.logout(uid,session['refresh_token'],True)
  with self.assertRaises(AuthError):self.identity.authenticate(session['access_token'])
 def test_password_reset_revokes_session(self):
  session=self.verified()
  self.identity.request_email('user@example.com','reset','127.0.0.1')
  row=self.row("SELECT * FROM auth_email_outbox WHERE template='password-reset'")
  token=json.loads(self.identity.cipher.decrypt(row['payload_encrypted'].encode()))['token']
  self.identity.consume(token,'reset','another strong password!')
  with self.assertRaises(AuthError):self.identity.authenticate(session['access_token'])
  self.identity.login('user@example.com','another strong password!','test','127.0.0.1')
 def test_no_automatic_link_by_email(self):
  self.register()
  self.identity.verifier=lambda *a:{'sub':'new','email':'user@example.com','email_verified':True}
  with self.assertRaises(AuthError) as e:self.identity.social('google','new',None,'test','ip')
  self.assertEqual(e.exception.code,'sign_in_to_existing_account_to_link')
 def test_social_reuses_subject(self):
  first=self.identity.social('google','subject',None,'test','ip')
  second=self.identity.social('google','subject',None,'test','ip')
  self.assertEqual(first['user']['id'],second['user']['id'])
 def test_apple_nonce_single_use(self):
  nonce=self.identity.challenge('ip')['nonce']
  self.identity.social('apple','subject',nonce,'test','ip')
  with self.assertRaises(AuthError):self.identity.social('apple','subject',nonce,'test','ip')
 def test_other_application_rejects_token(self):
  token=self.verified()['access_token']
  other=Identity(self.engine,{**self.config,'product':'bliss'})
  with self.assertRaises(AuthError):other.authenticate(token)
 def test_rate_limit_persists_failed_password(self):
  self.register()
  for n in range(5):
   with self.assertRaises(AuthError):self.identity.login('user@example.com','wrong','test','ip')
  with self.assertRaises(AuthError) as e:self.identity.login('user@example.com','wrong','test','ip')
  self.assertEqual(e.exception.status,429)
 def test_outbox_delivery_redacts_payload(self):
  self.register();messages=[]
  self.assertTrue(deliver_one(self.identity,messages.append))
  self.assertEqual(len(messages),1)
  self.assertEqual(self.row('SELECT payload_encrypted FROM auth_email_outbox')['payload_encrypted'],'')
 def test_development_mail_allowlist(self):
  self.register();self.config['mail_allowlist']=[];messages=[]
  deliver_one(self.identity,messages.append)
  self.assertEqual(messages,[])
  self.assertEqual(self.row('SELECT error_code FROM auth_email_outbox')['error_code'],'recipient_not_allowed')
 def test_email_failure_queues_retry(self):
  self.register()
  def fail(_):raise RuntimeError('private SMTP error')
  deliver_one(self.identity,fail)
  self.assertEqual(self.row('SELECT status FROM auth_email_outbox')['status'],'pending')
  self.assertEqual(self.row('SELECT error_code FROM auth_email_outbox')['error_code'],'delivery_failed')
 def test_mail_unconfigured_no_partial_account(self):
  self.config['mail_enabled']=False
  with self.assertRaises(AuthError):self.register()
  self.assertEqual(self.row('SELECT COUNT(*) n FROM app_users')['n'],0)

if __name__=='__main__':unittest.main()
