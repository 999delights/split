import hashlib,json,sqlite3,unittest
from sqlalchemy import text
from services.backend import test_mysql_app
from scripts.bind_recovered_members import bind

class BindingTest(unittest.TestCase):
 def setUp(self):
  self.f=test_mysql_app.DomainTest();self.f.setUp();self.g=self.f.group();self.mid=self.g['my_member_id']
  s=sqlite3.connect(':memory:');s.executescript('CREATE TABLE legacy_documents(path TEXT,payload TEXT); CREATE TABLE legacy_member_map(group_id TEXT,legacy_id TEXT,member_id TEXT);')
  s.execute('INSERT INTO legacy_documents VALUES(?,?)',('x/users/old',json.dumps({'id':'old','groups':[self.g['id']]})))
  s.execute('INSERT INTO legacy_member_map VALUES(?,?,?)',(self.g['id'],'old',self.mid));s.commit();self.raw=s.serialize();s.close();self.h=hashlib.sha256(self.raw).hexdigest()
  with self.f.identity.engine.begin() as c:
   c.execute(text('UPDATE split_group_users SET member_id=NULL'))
   c.execute(text('INSERT INTO split_imports(source_hash,user_id,counts_json) VALUES(:h,:u,:j)'),{'h':self.h,'u':self.f.owner,'j':'{}'})
 def tearDown(self):self.f.tearDown()
 def test_exact_binding_idempotent(self):
  for _ in range(2):self.assertEqual(bind(self.f.identity.engine,self.raw,self.h,True)['bindings'],1)
  with self.f.identity.engine.connect() as c:self.assertEqual(c.execute(text('SELECT member_id FROM split_group_users')).scalar(),self.mid)
 def test_wrong_hash_rejected(self):
  with self.assertRaises(ValueError):bind(self.f.identity.engine,self.raw,'bad',True)
 def test_conflicting_member_rejected(self):
  self.f.post('groups/'+self.g['id']+'/members',{'name':'Other'})
  with self.f.identity.engine.begin() as c:
   other=c.execute(text('SELECT id FROM split_members WHERE id!=:m'),{'m':self.mid}).scalar()
   c.execute(text('UPDATE split_group_users SET member_id=:m'),{'m':other})
  with self.assertRaises(ValueError):bind(self.f.identity.engine,self.raw,self.h,True)
