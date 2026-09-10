"""Explicit, transactional import of a read-only legacy SQLite snapshot into one account.

Default is validation/preview only. --apply imports; no UPDATE or DELETE of domain data.
"""
import argparse
import hashlib
import json
import sqlite3
from pathlib import Path
from sqlalchemy import text
from services.identity.runtime import load_config

TABLES={
 'groups':('id','name','icon','currency'),
 'members':('id','group_id','name'),
 'expenses':('id','group_id','name','amount','payer','created'),
 'shares':('expense_id','member_id','amount'),
 'settlements':('id','group_id','sender','receiver','amount','created'),
 'group_legacy_metadata':('group_id','color','profile_pic','date_json'),
}

def read_source(path):
 path=Path(path).resolve(strict=True)
 with sqlite3.connect(path.as_uri()+'?mode=ro',uri=True) as c:
  c.row_factory=sqlite3.Row
  c.execute('PRAGMA query_only=ON');c.execute('BEGIN')
  if c.execute('PRAGMA integrity_check').fetchone()[0]!='ok':raise ValueError('Invalid SQLite source')
  tables={r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table'")}
  data={}
  for table,cols in TABLES.items():
   if table not in tables:
    if table=='group_legacy_metadata':data[table]=[];continue
    raise ValueError('Missing source table: '+table)
   data[table]=[dict(r) for r in c.execute('SELECT '+','.join(cols)+' FROM '+table+' ORDER BY '+','.join(cols))]
  profiles=[dict(r) for r in c.execute('SELECT nickname FROM profile')]
  if len(profiles)!=1:raise ValueError('Expected one legacy profile')
  data['profile']=profiles[0]
 validate_source(data)
 # Logical snapshot checksum includes SQLite WAL contents read in the transaction.
 checksum=hashlib.sha256(json.dumps(data,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 return data,checksum

def validate_source(data):
 groups={r['id'] for r in data['groups']};members={r['id']:r['group_id'] for r in data['members']}
 expenses={r['id']:r for r in data['expenses']};totals={eid:0 for eid in expenses}
 if any(g not in groups for g in members.values()):raise ValueError('Orphan member')
 for e in expenses.values():
  if e['group_id'] not in groups or members.get(e['payer'])!=e['group_id']:raise ValueError('Invalid expense payer')
  if type(e['amount']) is not int or e['amount']<=0:raise ValueError('Invalid expense amount')
 for s in data['shares']:
  e=expenses.get(s['expense_id'])
  if not e or members.get(s['member_id'])!=e['group_id']:raise ValueError('Invalid share participant')
  if type(s['amount']) is not int or s['amount']<0:raise ValueError('Invalid share amount')
  totals[e['id']]+=s['amount']
 if any(totals[eid]!=e['amount'] for eid,e in expenses.items()):raise ValueError('Unbalanced expense shares')
 for s in data['settlements']:
  if s['group_id'] not in groups or any(members.get(s[k])!=s['group_id'] for k in ('sender','receiver')):raise ValueError('Invalid settlement participant')
  if s['sender']==s['receiver'] or type(s['amount']) is not int or s['amount']<=0:raise ValueError('Invalid settlement')
 if any(r['group_id'] not in groups for r in data['group_legacy_metadata']):raise ValueError('Orphan metadata')

def import_snapshot(identity,source,owner,apply=False):
 data,checksum=read_source(source)
 counts={table:len(data[table]) for table in TABLES}
 with identity.engine.begin() as c:
  user=identity.user(c,owner)
  if not user or user['status']!='active':raise ValueError('Explicit active owner account required')
  identity.lock_user(c,owner)
  verified=identity.one(c,'SELECT user_id FROM auth_email_addresses WHERE user_id=:u AND verified_at IS NOT NULL',u=owner)
  social=identity.one(c,"SELECT user_id FROM auth_identities WHERE user_id=:u AND provider IN ('google','apple')",u=owner)
  if not verified and not social:raise ValueError('Owner must have a verified sign-in identity')
  previous=identity.one(c,'SELECT user_id FROM split_imports WHERE source_hash=:h',h=checksum)
  if previous:
   if previous['user_id']!=owner:raise ValueError('Snapshot already belongs to a different account')
   return {'status':'already_imported','counts':counts,'source_hash':checksum}
  for row in data['groups']:
   if identity.one(c,'SELECT id FROM split_groups WHERE id=:g',g=row['id']):raise ValueError('Group already exists; explicit reconciliation required')
  if not apply:return {'status':'preview','counts':counts,'source_hash':checksum}
  if not identity.one(c,'SELECT id FROM split_profiles WHERE id=:u',u=owner):
   identity.execute(c,'INSERT INTO split_profiles(id,nickname) VALUES(:u,:n)',u=owner,n=data['profile']['nickname'])
  for table,cols in TABLES.items():
   if data[table]:
    c.execute(text('INSERT INTO split_'+table+'('+','.join(cols)+') VALUES('+','.join(':'+col for col in cols)+')'),data[table])
  for group in data['groups']:
   identity.execute(c,"INSERT INTO split_group_users(group_id,user_id,role) VALUES(:g,:u,'owner')",g=group['id'],u=owner)
  identity.execute(c,'INSERT INTO split_imports(source_hash,user_id,counts_json) VALUES(:h,:u,:j)',h=checksum,u=owner,j=json.dumps(counts))
 return {'status':'imported','counts':counts,'source_hash':checksum}

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 for name in ('source','owner','env-file','database-file'):parser.add_argument('--'+name,required=True)
 parser.add_argument('--apply',action='store_true');args=parser.parse_args()
 identity=load_config('split',args.env_file,args.database_file)
 print(json.dumps(import_snapshot(identity,args.source,args.owner,args.apply)))

if __name__=='__main__':main()
