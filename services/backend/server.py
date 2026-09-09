"""Split v0 API. Local development only; Firebase is never opened or modified."""
import json, os, sqlite3, secrets, threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

DB = os.environ.get('SPLIT_DB_PATH')
TOKEN = os.environ.get('SPLIT_DEV_TOKEN')
LOCK = threading.Lock()

def connect():
    c = sqlite3.connect(DB)
    c.row_factory = sqlite3.Row
    c.execute('PRAGMA foreign_keys=ON')
    return c

def initialize():
    if not DB or not TOKEN or len(TOKEN) < 24:
        raise RuntimeError('Set SPLIT_DB_PATH and SPLIT_DEV_TOKEN (at least 24 characters). Local v0 only.')
    Path(DB).parent.mkdir(parents=True, exist_ok=True)
    with connect() as c:
        c.executescript('''
        CREATE TABLE IF NOT EXISTS profile(id TEXT PRIMARY KEY, nickname TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS groups(id TEXT PRIMARY KEY,name TEXT NOT NULL,icon INTEGER NOT NULL,currency TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS members(id TEXT PRIMARY KEY,group_id TEXT REFERENCES groups(id),name TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS expenses(id TEXT PRIMARY KEY,group_id TEXT REFERENCES groups(id),name TEXT NOT NULL,amount INTEGER NOT NULL,payer TEXT REFERENCES members(id),created TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS shares(expense_id TEXT REFERENCES expenses(id) ON DELETE CASCADE,member_id TEXT REFERENCES members(id),amount INTEGER NOT NULL,PRIMARY KEY(expense_id,member_id));
        CREATE TABLE IF NOT EXISTS settlements(id TEXT PRIMARY KEY,group_id TEXT REFERENCES groups(id),sender TEXT REFERENCES members(id),receiver TEXT REFERENCES members(id),amount INTEGER NOT NULL,created TEXT NOT NULL);
        INSERT OR IGNORE INTO profile VALUES('local','Andrei');
        ''')

def now(): return datetime.now(timezone.utc).isoformat()
def uid(): return secrets.token_hex(12)
def string(d,k):
    v=d.get(k)
    if not isinstance(v,str) or not 1<=len(v.strip())<=80: raise ValueError('Enter a valid '+k)
    return v.strip()
def integer(v):
    if type(v) is not int or not 1<=v<=100000000: raise ValueError('Invalid amount')
    return v

def snapshot(c):
    result={'profile':dict(c.execute('SELECT * FROM profile').fetchone()),'groups':[]}
    for row in c.execute('SELECT * FROM groups ORDER BY rowid DESC'):
        g=dict(row); ident=g['id']
        if c.execute("SELECT 1 FROM sqlite_master WHERE name='group_legacy_metadata'").fetchone():
            meta=c.execute('SELECT color,profile_pic,date_json FROM group_legacy_metadata WHERE group_id=?',(ident,)).fetchone()
            if meta: g.update(dict(meta))
        g['members']=[dict(x) for x in c.execute('SELECT * FROM members WHERE group_id=?',(ident,))]
        balances={x['id']:0 for x in g['members']}
        g['expenses']=[]
        for row in c.execute('SELECT * FROM expenses WHERE group_id=? ORDER BY created DESC',(ident,)):
            e=dict(row); e['shares']={x['member_id']:x['amount'] for x in c.execute('SELECT * FROM shares WHERE expense_id=?',(e['id'],))}
            balances[e['payer']]+=e['amount']
            for m,a in e['shares'].items(): balances[m]-=a
            g['expenses'].append(e)
        g['settlements']=[dict(x) for x in c.execute('SELECT * FROM settlements WHERE group_id=?',(ident,))]
        for s in g['settlements']:
            balances[s['sender']]+=s['amount']; balances[s['receiver']]-=s['amount']
        g['balances']=balances
        result['groups'].append(g)
    return result

def mutate(c,path,d):
    if path=='/profile':
        c.execute('UPDATE profile SET nickname=?',(string(d,'nickname'),)); return
    if path=='/groups':
        name=string(d,'name'); currency=d.get('currency','RON'); icon=d.get('icon',1)
        if currency not in ('RON','EUR','USD','GBP') or type(icon) is not int or not 1<=icon<=20: raise ValueError('Invalid group settings')
        g=uid(); c.execute('INSERT INTO groups VALUES(?,?,?,?)',(g,name,icon,currency))
        c.execute('INSERT INTO members VALUES(?,?,?)',(uid(),g,'Me')); return
    parts=path.strip('/').split('/')
    if len(parts)<3 or parts[0]!='groups': raise ValueError('Unknown operation')
    g=parts[1]
    if not c.execute('SELECT 1 FROM groups WHERE id=?',(g,)).fetchone(): raise ValueError('Group not found')
    members={x['id'] for x in c.execute('SELECT id FROM members WHERE group_id=?',(g,))}
    if parts[2]=='members':
        c.execute('INSERT INTO members VALUES(?,?,?)',(uid(),g,string(d,'name')))
    elif parts[2]=='settings':
        c.execute('UPDATE groups SET name=? WHERE id=?',(string(d,'name'),g))
    elif parts[2]=='expenses':
        name=string(d,'name'); amount=integer(d.get('amount')); payer=d.get('payer'); shares=d.get('shares')
        if payer not in members or not isinstance(shares,dict) or not shares or not set(shares)<=members: raise ValueError('Select group participants')
        if any(type(a) is not int or a<0 for a in shares.values()) or sum(shares.values())!=amount: raise ValueError('Shares must total the expense')
        e=parts[3] if len(parts)==4 else uid()
        if len(parts)==4:
            if not c.execute('SELECT 1 FROM expenses WHERE id=? AND group_id=?',(e,g)).fetchone(): raise ValueError('Expense not found')
            c.execute('UPDATE expenses SET name=?,amount=?,payer=? WHERE id=?',(name,amount,payer,e)); c.execute('DELETE FROM shares WHERE expense_id=?',(e,))
        else: c.execute('INSERT INTO expenses VALUES(?,?,?,?,?,?)',(e,g,name,amount,payer,now()))
        c.executemany('INSERT INTO shares VALUES(?,?,?)',[(e,m,a) for m,a in shares.items()])
    elif parts[2]=='settlements':
        sender=d.get('sender'); receiver=d.get('receiver'); amount=integer(d.get('amount'))
        if sender not in members or receiver not in members or sender==receiver: raise ValueError('Invalid participants')
        balances=next(x for x in snapshot(c)['groups'] if x['id']==g)['balances']
        if amount>min(-balances[sender],balances[receiver]): raise ValueError('Amount exceeds outstanding balance')
        c.execute('INSERT INTO settlements VALUES(?,?,?,?,?,?)',(uid(),g,sender,receiver,amount,now()))
    else: raise ValueError('Unknown operation')

class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def respond(self,code,value):
        data=json.dumps(value).encode(); self.send_response(code); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
    def do_GET(self):
        if self.path=='/health': return self.respond(200,{'status':'ok','mode':'local-v0'})
        if not secrets.compare_digest(self.headers.get('Authorization',''),'Bearer '+TOKEN): return self.respond(401,{'error':'Authentication required'})
        if self.path!='/api/v1/state': return self.respond(404,{'error':'Not found'})
        with connect() as c: self.respond(200,snapshot(c))
    def do_POST(self):
        if not secrets.compare_digest(self.headers.get('Authorization',''),'Bearer '+TOKEN): return self.respond(401,{'error':'Authentication required'})
        try:
            size=int(self.headers.get('Content-Length','0'))
            if not 0<size<=32768: raise ValueError('Invalid request size')
            d=json.loads(self.rfile.read(size))
            if not isinstance(d,dict) or not self.path.startswith('/api/v1/'): raise ValueError('Invalid request')
            with LOCK,connect() as c:
                mutate(c,self.path[len('/api/v1'):],d)
                result=snapshot(c)
            self.respond(200,result)
        except (ValueError,TypeError,sqlite3.IntegrityError) as e: self.respond(400,{'error':str(e)})
        except Exception: self.respond(500,{'error':'Unable to save. Please retry.'})

if __name__=='__main__':
    initialize()
    ThreadingHTTPServer(('127.0.0.1',int(os.environ.get('PORT','3400'))),Handler).serve_forever()
