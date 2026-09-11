import time
import unittest
from types import SimpleNamespace
from cryptography.hazmat.primitives.asymmetric import rsa
import jwt
from . import test_identity
from .core import AuthError,digest

class ProviderTest(unittest.TestCase):
 def setUp(self):
  self.fixture=test_identity.IdentityTest();self.fixture.setUp()
  self.identity=self.fixture.identity
  self.private=rsa.generate_private_key(public_exponent=65537,key_size=2048)
  self.identity.config.update(google_client_ids=['google-client'],apple_client_ids=['apple-client'])
  self.identity.jwks={p:SimpleNamespace(get_signing_key_from_jwt=lambda token:SimpleNamespace(key=self.private.public_key())) for p in ('google','apple')}
 def tearDown(self):self.fixture.tearDown()
 def token(self,provider='google',**overrides):
  now=int(time.time());claims={'sub':'subject','iss':'https://accounts.google.com' if provider=='google' else 'https://appleid.apple.com','aud':provider+'-client','iat':now,'exp':now+300,'email':'verified@example.com','email_verified':True,**overrides}
  return jwt.encode(claims,self.private,algorithm='RS256')
 def test_real_signature_and_audience(self):
  self.assertEqual(self.identity.verify_provider('google',self.token(),None)['sub'],'subject')
  for token in (self.token(aud='another-product'),self.token(iss='https://attacker.invalid'),self.token(exp=1)):
   with self.assertRaises(AuthError):self.identity.verify_provider('google',token,None)
 def test_wrong_signing_key_rejected(self):
  token=self.token();other=rsa.generate_private_key(public_exponent=65537,key_size=2048)
  self.identity.jwks['google']=SimpleNamespace(get_signing_key_from_jwt=lambda _:SimpleNamespace(key=other.public_key()))
  with self.assertRaises(AuthError):self.identity.verify_provider('google',token,None)
 def test_apple_nonce_is_bound_to_token(self):
  token=self.token('apple',nonce=digest('expected'))
  self.identity.verify_provider('apple',token,'expected')
  with self.assertRaises(AuthError):self.identity.verify_provider('apple',token,'wrong')

 def test_google_unverified_rejected(self):
  self.identity.verifier=self.identity.verify_provider
  for verified in (False,'false',None,1):
   with self.assertRaises(AuthError):self.identity.social('google',self.token(email_verified=verified),None,'iOS','test')
 def test_google_repeat_and_logout(self):
  self.identity.verifier=self.identity.verify_provider
  first=self.identity.social('google',self.token(),None,'iOS','one')
  second=self.identity.social('google',self.token(),None,'Android','two')
  self.assertEqual(first['user']['id'],second['user']['id'])
  fresh=self.identity.refresh(first['refresh_token'])
  self.identity.logout(first['user']['id'],fresh['refresh_token'])
  with self.assertRaises(AuthError):self.identity.authenticate(fresh['access_token'])
  self.identity.authenticate(second['access_token'])
