"""Bind existing imported rows using the original legacy identity map, not names/order."""
import argparse,hashlib,json,sqlite3
from pathlib import Path
from sqlalchemy import create_engine,text,URL
from dotenv import dotenv_values

def bind(engine,raw,expected,apply=False):
 if hashlib.sha256(raw).hexdigest()!=expected:raise ValueError('Source checksum mismatch')
 s=sqlite3.connect(':memory:');s.deserialize(raw)
 try:
  users=[json.loads(r[0]) for r in s.execute("SELECT payload FROM legacy_documents WHERE path LIKE '%/users/%'")]
  if len(users)!=1:raise ValueError('Ambiguous source identity')
  legacy=users[0]['id'];groups=users[0]['groups']
  bindings=[]
  for gid in groups:
   rows=list(s.execute('SELECT member_id FROM legacy_member_map WHERE group_id=? AND legacy_id=?',(gid,legacy)))
   if len(rows)!=1:raise ValueError('Missing source member mapping')
   bindings.append((gid,rows[0][0]))
 finally:s.close()
 with engine.begin() as c:
  suffix=' FOR UPDATE' if c.dialect.name=='mysql' else ''
  ledger=c.execute(text('SELECT user_id FROM split_imports WHERE source_hash=:h'+suffix),{'h':expected}).one()
  uid=ledger[0]
  for gid,mid in bindings:
   row=c.execute(text("SELECT u.member_id FROM split_group_users u JOIN split_members m ON m.group_id=u.group_id AND m.id=:m WHERE u.group_id=:g AND u.user_id=:u AND u.role='owner'"+suffix),{'m':mid,'g':gid,'u':uid}).one()
   if row[0] not in (None,mid):raise ValueError('Conflicting binding')
   if apply:c.execute(text('UPDATE split_group_users SET member_id=:m WHERE group_id=:g AND user_id=:u'),{'m':mid,'g':gid,'u':uid})
  return {'status':'bound' if apply else 'ready','bindings':len(bindings)}

def main():
 p=argparse.ArgumentParser();p.add_argument('--source',required=True);p.add_argument('--sha256',required=True);p.add_argument('--database-file',required=True);p.add_argument('--apply',action='store_true');a=p.parse_args();cfg=dotenv_values(a.database_file)
 if cfg.get('APP_DB_NAME')!='dev_split_db':raise ValueError('DEV only')
 e=create_engine(URL.create('mysql+pymysql',username=cfg['APP_DB_USER'],password=cfg['APP_DB_PASSWORD'],host=cfg['APP_DB_HOST'],port=int(cfg['APP_DB_PORT']),database=cfg['APP_DB_NAME']),hide_parameters=True)
 try:print(json.dumps(bind(e,Path(a.source).read_bytes(),a.sha256,a.apply)))
 finally:e.dispose()
if __name__=='__main__':
 try:main()
 except Exception:raise SystemExit('Binding validation failed; no details logged.')
