"""Import validated cached legacy documents into a NEW local database only."""
import sys,json,importlib.util,sqlite3
from pathlib import Path
from decimal import Decimal
from datetime import datetime,timezone
spec=importlib.util.spec_from_file_location('split_api',Path(__file__).resolve().parents[1]/'services/backend/server.py');api=importlib.util.module_from_spec(spec);spec.loader.exec_module(api)
def minor(v):
 n=Decimal(v or '0')*100
 if not n.is_finite() or n!=n.to_integral_value():raise ValueError('Non-exact minor units; manual reconciliation required')
 return int(n)
def run(source,target):
 target=Path(target)
 if target.exists():raise ValueError('Destination already exists; refusing to overwrite')
 export=json.loads(Path(source).read_text());docs=export['documents'];kinds={k:[] for k in ['groups','users','payments']}
 if any(d.get('committed_mutations') for d in docs):raise ValueError('Pending writes require a fresh snapshot')
 for d in docs:
  k=d['path'].split('/')[-2]
  if k in kinds:kinds[k].append(d['fields'])
 if len(kinds['users'])!=1:raise ValueError('Select the local profile explicitly for multiple accounts')
 user=kinds['users'][0];groups=kinds['groups'];payments=kinds['payments']
 assert set(user['groups'])=={g['id'] for g in groups},'Incomplete group cache'
 for g in groups:
  ps=[p for p in payments if p['group']==g['id']]
  assert set(g['paymentsId'])=={p['id'] for p in ps},'Missing expense references'
  assert set(g['users'])=={user['id']},'Additional registered identities require export'
  members=set(g['users'])|set(g['createdUsers'])
  for p in ps:
   assert p['by'] in members and set(p['split'])<=members,'Unknown participant'
   assert sum(minor(v) for v in p['split'].values())==minor(p['price']),'Unbalanced expense'
 api.DB=str(target);api.TOKEN='local-import-validation-only';api.initialize()
 report=[]
 with api.connect() as c:
  c.execute('CREATE TABLE legacy_documents(path TEXT PRIMARY KEY,payload TEXT NOT NULL)')
  c.execute('CREATE TABLE legacy_member_map(group_id TEXT,legacy_id TEXT,member_id TEXT,PRIMARY KEY(group_id,legacy_id))')
  c.execute('CREATE TABLE group_legacy_metadata(group_id TEXT PRIMARY KEY,color TEXT,profile_pic TEXT,date_json TEXT,currency_known INTEGER DEFAULT 0)')
  c.execute('UPDATE profile SET nickname=?',(user['nickname'],))
  for d in docs:c.execute('INSERT INTO legacy_documents VALUES(?,?)',(d['path'],json.dumps(d['fields'])))
  for g in sorted(groups,key=lambda g:g['date']['seconds']):
   gid=g['id'];icon=int(g['profilePic'].replace('group',''))
   c.execute('INSERT INTO groups VALUES(?,?,?,?)',(gid,g['name'],icon,''))
   c.execute('INSERT INTO group_legacy_metadata VALUES(?,?,?,?,0)',(gid,g['color'],g['profilePic'],json.dumps(g['date'])))
   names={user['id']:'Me',**g['createdUsers']};ids={m:gid+':'+m for m in names}
   for m,name in names.items():
    c.execute('INSERT INTO members VALUES(?,?,?)',(ids[m],gid,name));c.execute('INSERT INTO legacy_member_map VALUES(?,?,?)',(gid,m,ids[m]))
   for p in payments:
    if p['group']!=gid:continue
    date=datetime.fromtimestamp(p['date']['seconds'],timezone.utc).isoformat()
    c.execute('INSERT INTO expenses VALUES(?,?,?,?,?,?)',(p['id'],gid,p['name'],minor(p['price']),ids[p['by']],date))
    c.executemany('INSERT INTO shares VALUES(?,?,?)',[(p['id'],ids[m],minor(v)) for m,v in p['split'].items()])
  for g in api.snapshot(c)['groups']:
   assert sum(g['balances'].values())==0
   report.append({'name':g['name'],'payments':len(g['expenses']),'my_balance_minor':g['balances'][g['members'][0]['id']]})
 target.chmod(0o600)
 return report
if __name__=='__main__':print(json.dumps(run(sys.argv[1],sys.argv[2]),indent=2))
