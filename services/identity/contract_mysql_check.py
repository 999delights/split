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
 identity.logout(uid,refreshed['refresh_token'])
 print('MySQL account contract: structured device, session rotation, Admin metadata and template revision passed.')
