"""Exercise new account contract against disposable MySQL after real migrations."""
import os
from unittest.mock import patch
from flask import Flask
from .admin_api import blueprint
from . import templates

def check_contract(identity,uid):
 with identity.engine.begin() as c:
  device,_=identity.record_device(c,uid,dict(id='a1b2c3d4-1111-4222-8333-123456789abc',platform='android',name='CI Android',model='CI',app_version='1+1'))
  session=identity.issue(c,uid,dict(id='a1b2c3d4-1111-4222-8333-123456789abc',platform='android',name='CI Android'),'email')
 refreshed=identity.refresh(session['refresh_token'])
 app=Flask(__name__);app.register_blueprint(blueprint(identity),url_prefix='/admin')
 with patch.dict(os.environ,{identity.product.upper()+'_ADMIN_READ_TOKEN':'r'*40}):
  response=app.test_client().get('/admin/users/'+uid,headers={'Authorization':'Bearer '+'r'*40})
  assert response.status_code==200,response.json
  assert response.json['user']['devices'][0]['id']==device
  assert response.json['user']['active_sessions']==1,response.json
 templates.save(identity,'welcome',dict(subject='Welcome {{app_name}}',body='CI template',expected_revision=0,actor='mysql-ci'))
 assert templates.get(identity,'welcome')['revision']==1
 from concurrent.futures import ThreadPoolExecutor
 from .core import AuthError
 def update_template():
  try:return templates.save(identity,'welcome',dict(subject='Changed',body='Concurrent edit',expected_revision=1,actor='mysql-ci'))
  except AuthError as e:return e.code
 with ThreadPoolExecutor(max_workers=2) as executor: results=list(executor.map(lambda _:update_template(),range(2)))
 assert sum(isinstance(r,dict) for r in results)==1,results
 assert 'template_revision_conflict' in results,results
 check_branded_mail(identity,uid)
 identity.logout(uid,refreshed['refresh_token'])
 print('MySQL account contract: structured device, session rotation, Admin metadata and template revision passed.')

def check_branded_mail(identity, uid):
 """Real constraints/transaction behavior; never use the SMTP transport."""
 from concurrent.futures import ThreadPoolExecutor
 from sqlalchemy.exc import IntegrityError
 from .core import AuthError
 with identity.engine.connect() as c:
  email=identity.user(c,uid)['email']
 original=identity.verifier
 identity.verifier=lambda p,t,n:dict(sub=t,email=email,email_verified=True)
 def linked_count():
  with identity.engine.connect() as c:
   return identity.one(c,"SELECT COUNT(*) n FROM auth_email_outbox WHERE user_id=:u AND template='identity-linked'",u=uid)['n']
 before=linked_count()
 try:
  def link():
   try:return identity.social('google','mysql-template-link',None,None,'template-ci',link_user=uid)
   except IntegrityError:return 'concurrent_identity_insert'
  with ThreadPoolExecutor(max_workers=2) as executor: results=list(executor.map(lambda _:link(),range(2)))
  assert any(isinstance(r,dict) and r.get('ok') for r in results)
  assert linked_count()==before+1
  identity.social('google','mysql-template-link',None,None,'template-ci',link_user=uid)
  assert linked_count()==before+1
  enqueue=identity.enqueue
  def rollback(*args,**kwargs):
   enqueue(*args,**kwargs)
   raise RuntimeError('Intentional isolated test rollback')
  with patch.object(identity,'enqueue',side_effect=rollback):
   try:identity.social('google','mysql-rollback-link',None,None,'template-ci',link_user=uid)
   except RuntimeError:pass
   else:raise AssertionError('Rollback was not exercised')
  assert linked_count()==before+1
  with identity.engine.connect() as c:
   assert not identity.one(c,"SELECT user_id FROM auth_identities WHERE provider='google' AND subject='mysql-rollback-link'")
  for key in templates.TEMPLATES:
   action='https://preview.invalid/confirmation' if key in templates.ACTIONS else None
   preview=templates.render(identity,key,action_url=action,context={'display_name':'Alex','provider':'google','preview':True})
   assert '<html' in preview['html'] and preview['text']
   assert 'token=' not in preview['html']
  assert templates.get(identity,'security-alert')['automatically_triggered'] is False
 finally:identity.verifier=original
 print('MySQL branded mail: six renders, concurrent link deduplication and transactional rollback passed; no SMTP.')
