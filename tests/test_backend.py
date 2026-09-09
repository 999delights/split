import importlib.util, tempfile, unittest, os
spec=importlib.util.spec_from_file_location('api','services/backend/server.py');api=importlib.util.module_from_spec(spec);spec.loader.exec_module(api)
class BackendTest(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();api.DB=self.tmp.name+'/test.db';api.TOKEN='x'*32;api.initialize()
 def tearDown(self): self.tmp.cleanup()
 def test_expenses_balance_edit_settle_and_isolation(self):
  with api.connect() as c:
   api.mutate(c,'/groups',{'name':'Trip'});g=api.snapshot(c)['groups'][0];gid=g['id'];a=g['members'][0]['id']
   api.mutate(c,f'/groups/{gid}/members',{'name':'Ana'});g=api.snapshot(c)['groups'][0];b=g['members'][1]['id']
   api.mutate(c,f'/groups/{gid}/expenses',{'name':'Dinner','amount':10001,'payer':a,'shares':{a:5001,b:5000}})
   g=api.snapshot(c)['groups'][0];self.assertEqual(g['balances'],{a:5000,b:-5000});self.assertEqual(sum(g['balances'].values()),0)
   with self.assertRaises(ValueError):api.mutate(c,f'/groups/{gid}/expenses',{'name':'Bad','amount':10,'payer':a,'shares':{a:9}})
   with self.assertRaises(ValueError):api.mutate(c,f'/groups/{gid}/expenses',{'name':'Bad','amount':10,'payer':'outsider','shares':{a:10}})
   with self.assertRaises(ValueError):api.mutate(c,f'/groups/{gid}/settlements',{'sender':b,'receiver':a,'amount':5001})
   api.mutate(c,f'/groups/{gid}/settlements',{'sender':b,'receiver':a,'amount':5000})
   self.assertEqual(api.snapshot(c)['groups'][0]['balances'],{a:0,b:0})
 def test_invalid_money(self):
  for value in [1.1,True,-1,0,100000001,'10']:
   with self.assertRaises(ValueError):api.integer(value)
if __name__=='__main__':unittest.main()
