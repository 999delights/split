import unittest
from flask import Flask
from .http_api import blueprint
from .core import AuthError

class Stub:
 def register(self,*args):raise AuthError('email_delivery_not_configured',503)
 def authenticate(self,*args):raise AuthError('invalid_session',401)

class HttpTests(unittest.TestCase):
 def setUp(self):
  app=Flask(__name__);app.register_blueprint(blueprint(Stub()),url_prefix='/api/auth');self.client=app.test_client()
 def test_registration_does_not_issue_session_when_mail_unconfigured(self):
  r=self.client.post('/api/auth/register',json={'email':'test@example.com','password':'strong password!','name':'Test'})
  self.assertEqual(r.status_code,503);self.assertNotIn('access_token',r.json)
 def test_action_scanners_do_not_consume_link(self):
  r=self.client.get('/api/auth/action')
  self.assertEqual(r.status_code,200)
  self.assertEqual(r.headers['Cache-Control'],'no-store')
  self.assertIn("frame-ancestors 'none'",r.headers['Content-Security-Policy'])
  self.assertIn(b"addEventListener('submit'",r.data)
 def test_profile_requires_authorization(self):
  self.assertEqual(self.client.get('/api/auth/me').status_code,401)
 def test_invalid_json(self):
  self.assertEqual(self.client.post('/api/auth/register',json=[]).status_code,400)
 def test_body_limit(self):
  self.assertEqual(self.client.post('/api/auth/register',data='x'*40000).status_code,413)

if __name__=='__main__':unittest.main()
