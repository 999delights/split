"""Domain authorization and balances using a disposable database."""
import re
import unittest
from pathlib import Path
from sqlalchemy import text
from services.identity import test_identity
from .mysql_app import create_app

class DomainTest(unittest.TestCase):
 def setUp(self):
  self.fixture=test_identity.IdentityTest();self.fixture.setUp()
  self.identity=self.fixture.identity
  with self.identity.engine.begin() as c:
   sql=(Path(__file__).resolve().parents[2]/'infra/db/migrations/002_split_domain.sql').read_text()
   for statement in sql.split(';'):
    if not statement.strip():continue
    statement=re.sub(r'\) ENGINE=.*',')',statement,flags=re.S).replace('CURRENT_TIMESTAMP(6)','CURRENT_TIMESTAMP')
    c.execute(text(statement))
  self.client=create_app(self.identity).test_client()
  session=self.fixture.verified();self.owner=session['user']['id']
  self.headers={'Authorization':'Bearer '+session['access_token']}
  other=self.identity.social('google','other',None,'test','ip')
  self.other_headers={'Authorization':'Bearer '+other['access_token']}
 def tearDown(self):self.fixture.tearDown()
 def post(self,path,data,headers=None):return self.client.post('/api/v1/'+path,json=data,headers=headers or self.headers)
 def group(self):
  response=self.post('groups',{'name':'Trip'})
  self.assertEqual(response.status_code,200,response.json)
  return response.json['groups'][0]
 def test_anonymous_and_cross_user_access(self):
  self.assertEqual(self.client.get('/api/v1/state').status_code,401)
  group=self.group()
  state=self.client.get('/api/v1/state',headers=self.other_headers)
  self.assertEqual(state.json['groups'],[])
  self.assertEqual(self.post('groups/'+group['id']+'/members',{'name':'Intruder'},self.other_headers).status_code,404)
 def test_expense_and_settlement_preserve_balances(self):
  group=self.group();gid=group['id'];a=group['members'][0]['id']
  group=self.post('groups/'+gid+'/members',{'name':'Friend'}).json['groups'][0]
  b=next(m['id'] for m in group['members'] if m['id']!=a)
  payload={'name':'Dinner','amount':1000,'payer':a,'shares':{a:500,b:500}}
  r=self.post('groups/'+gid+'/expenses',payload)
  self.assertEqual(r.status_code,200,r.json)
  self.assertEqual(r.json['groups'][0]['balances'],{a:500,b:-500})
  self.assertEqual(self.post('groups/'+gid+'/settlements',{'sender':b,'receiver':a,'amount':501}).status_code,400)
  r=self.post('groups/'+gid+'/settlements',{'sender':b,'receiver':a,'amount':500})
  self.assertEqual(r.status_code,200,r.json)
  self.assertEqual(r.json['groups'][0]['balances'],{a:0,b:0})
 def test_invalid_share_total_rolls_back(self):
  group=self.group();a=group['members'][0]['id']
  r=self.post('groups/'+group['id']+'/expenses',{'name':'Invalid','amount':100,'payer':a,'shares':{a:99}})
  self.assertEqual(r.status_code,400)
  self.assertEqual(self.client.get('/api/v1/state',headers=self.headers).json['groups'][0]['expenses'],[])
 def test_profile_is_scoped_and_logout_blocks_domain(self):
  self.post('profile',{'nickname':'Owner'})
  state=self.client.get('/api/v1/state',headers=self.other_headers)
  self.assertNotEqual(state.json['profile']['nickname'],'Owner')
  self.identity.logout(self.owner,None,True)
  self.assertEqual(self.client.get('/api/v1/state',headers=self.headers).status_code,401)
