"""DEV-only, transactional import of the validated local recovery database.
No network service, no migration, no credentials or personal data in output.
"""
import argparse
import hashlib
import json
import sqlite3
from pathlib import Path
from sqlalchemy import create_engine, text, URL
from dotenv import dotenv_values

COLUMNS = {
 'groups': 'id,name,icon,currency',
 'members': 'id,group_id,name',
 'expenses': 'id,group_id,name,amount,payer,created',
 'shares': 'expense_id,member_id,amount',
 'settlements': 'id,group_id,sender,receiver,amount,created',
 'group_legacy_metadata': 'group_id,color,profile_pic,date_json',
}

def load_source(path, expected_hash):
 path=Path(path).resolve()
 raw=path.read_bytes()
 if hashlib.sha256(raw).hexdigest()!=expected_hash:raise ValueError('Source checksum mismatch')
 # Parse an immutable in-memory copy of the exact bytes we verified.
 db=sqlite3.connect(':memory:');db.deserialize(raw);db.row_factory=sqlite3.Row
 try:
  if db.execute('PRAGMA integrity_check').fetchone()[0]!='ok':raise ValueError('Source integrity failed')
  data={t:[dict(r) for r in db.execute('SELECT '+cols+' FROM '+t)] for t,cols in COLUMNS.items()}
 finally:db.close()
 groups={r['id'] for r in data['groups']};members={r['id']:r['group_id'] for r in data['members']}
 if not groups:raise ValueError('Empty recovery')
 if any(g not in groups for g in members.values()):raise ValueError('Unknown group')
 expenses={r['id']:r for r in data['expenses']};totals={e:0 for e in expenses}
 for row in data['shares']:
  e=expenses.get(row['expense_id'])
  if not e or members.get(row['member_id'])!=e['group_id']:raise ValueError('Invalid share relation')
  if type(row['amount']) is not int or row['amount']<0:raise ValueError('Invalid amount')
  totals[e['id']]+=row['amount']
 for e in expenses.values():
  if members.get(e['payer'])!=e['group_id'] or type(e['amount']) is not int or e['amount']<0 or totals[e['id']]!=e['amount']:raise ValueError('Unbalanced expense')
 for s in data['settlements']:
  if any(members.get(s[k])!=s['group_id'] for k in ('sender','receiver')) or type(s['amount']) is not int or s['amount']<0:raise ValueError('Invalid settlement')
 if any(r['group_id'] not in groups for r in data['group_legacy_metadata']):raise ValueError('Invalid metadata')
 return data

def run(engine,data,source_hash,email,apply=False):
 counts={k:len(v) for k,v in data.items()}
 with engine.begin() as c:
  suffix=' FOR UPDATE' if c.dialect.name=='mysql' else ''
  users=list(c.execute(text("SELECT DISTINCT u.id FROM app_users u JOIN auth_identities i ON i.user_id=u.id JOIN auth_email_addresses e ON e.user_id=u.id WHERE u.status='active' AND i.provider='google' AND LOWER(i.email)=:email AND LOWER(e.email)=:email AND e.verified_at IS NOT NULL"),{'email':email.lower()}).scalars())
  if len(users)!=1:raise ValueError('Expected exactly one verified Google account')
  uid=users[0]
  c.execute(text('SELECT id FROM app_users WHERE id=:u'+suffix),{'u':uid}).first()
  previous=c.execute(text('SELECT user_id FROM split_imports WHERE source_hash=:h'),{'h':source_hash}).first()
  if previous:
   if previous[0]!=uid:raise ValueError('Recovery already belongs to another account')
   return {'status':'already_imported','counts':counts}
  for g in data['groups']:
   if c.execute(text('SELECT id FROM split_groups WHERE id=:g'),{'g':g['id']}).first():raise ValueError('Group ID collision; no data changed')
  if not apply:return {'status':'ready','counts':counts}
  for table,cols in COLUMNS.items():
   if data[table]:c.execute(text('INSERT INTO split_'+table+' ('+cols+') VALUES ('+','.join(':'+x for x in cols.split(','))+')'),data[table])
  c.execute(text("INSERT INTO split_group_users(group_id,user_id,role) VALUES(:g,:u,'owner')"),[{'g':g['id'],'u':uid} for g in data['groups']])
  # Exact field equality includes all amounts, dates, payer/share links and metadata.
  for table,cols in COLUMNS.items():
   keys={'shares':('expense_id','member_id'),'group_legacy_metadata':('group_id',)}.get(table,('id',))
   for row in data[table]:
    saved=c.execute(text('SELECT '+cols+' FROM split_'+table+' WHERE '+' AND '.join(k+'=:'+k for k in keys)),{k:row[k] for k in keys}).mappings().one()
    if dict(saved)!=row:raise ValueError('Destination mismatch; transaction rolled back')
  c.execute(text('INSERT INTO split_imports(source_hash,user_id,counts_json) VALUES(:h,:u,:c)'),{'h':source_hash,'u':uid,'c':json.dumps(counts)})
  return {'status':'imported','counts':counts,'exact_rows_verified':True}

def main():
 p=argparse.ArgumentParser();p.add_argument('--source',required=True);p.add_argument('--sha256',required=True);p.add_argument('--email',required=True);p.add_argument('--database-file',required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
 data=load_source(a.source,a.sha256);cfg=dotenv_values(a.database_file)
 if cfg.get('APP_DB_NAME')!='dev_split_db':raise ValueError('Only dev_split_db is allowed')
 engine=create_engine(URL.create('mysql+pymysql',username=cfg['APP_DB_USER'],password=cfg['APP_DB_PASSWORD'],host=cfg['APP_DB_HOST'],port=int(cfg['APP_DB_PORT']),database=cfg['APP_DB_NAME']),hide_parameters=True)
 try:print(json.dumps(run(engine,data,a.sha256,a.email,a.apply)))
 finally:engine.dispose()

if __name__=='__main__':
 try:main()
 except Exception:
  raise SystemExit('Import stopped. Source/account/transaction validation failed; no secret details logged.')
