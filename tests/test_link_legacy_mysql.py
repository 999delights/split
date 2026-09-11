import unittest
from sqlalchemy import text
from services.backend import test_mysql_app
from scripts.link_legacy_mysql import run

class ImportTest(unittest.TestCase):
 def setUp(self):
  self.f=test_mysql_app.DomainTest();self.f.setUp();self.engine=self.f.identity.engine
  with self.engine.begin() as c:c.execute(text("INSERT INTO auth_identities(id,user_id,provider,subject,email) VALUES('test-google',:u,'google','test-subject','user@example.com')"),{'u':self.f.owner})
  self.data={'groups':[{'id':'g','name':'Trip','icon':1,'currency':''}], 'members':[{'id':'m','group_id':'g','name':'Me'}], 'expenses':[{'id':'e','group_id':'g','name':'Dinner','amount':125,'payer':'m','created':'2020-01-01'}], 'shares':[{'expense_id':'e','member_id':'m','amount':125}], 'settlements':[], 'group_legacy_metadata':[]}
 def tearDown(self):self.f.tearDown()
 def count(self):
  with self.engine.connect() as c:return c.execute(text('SELECT COUNT(*) FROM split_groups')).scalar()
 def test_dry_run_and_idempotency(self):
  self.assertEqual(run(self.engine,self.data,'a'*64,'user@example.com')['status'],'ready');self.assertEqual(self.count(),0)
  self.assertEqual(run(self.engine,self.data,'a'*64,'user@example.com',True)['status'],'imported')
  self.assertEqual(run(self.engine,self.data,'a'*64,'user@example.com',True)['status'],'already_imported');self.assertEqual(self.count(),1)
  with self.engine.connect() as c:self.assertEqual(c.execute(text('SELECT user_id FROM split_group_users')).scalar(),self.f.owner)
 def test_unknown_account_rejected(self):
  with self.assertRaises(ValueError):run(self.engine,self.data,'a'*64,'wrong@example.com',True)
  self.assertEqual(self.count(),0)
 def test_collision_does_not_overwrite(self):
  run(self.engine,self.data,'a'*64,'user@example.com',True)
  with self.assertRaises(ValueError):run(self.engine,self.data,'b'*64,'user@example.com',True)
  self.assertEqual(self.count(),1)
 def test_partial_write_rolls_back(self):
  self.data['shares'].append(dict(self.data['shares'][0]))
  with self.assertRaises(Exception):run(self.engine,self.data,'a'*64,'user@example.com',True)
  self.assertEqual(self.count(),0)
