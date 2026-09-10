"""Authenticated Split API over MySQL. Reuses the v0 expense calculation rules."""
import re
from flask import Flask,request,jsonify
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from services.identity.core import AuthError
from services.identity.http_api import blueprint
from .server import snapshot,mutate

TABLES=('groups','members','expenses','shares','settlements','group_legacy_metadata')
COLUMNS={'groups':'id,name,icon,currency','members':'id,group_id,name','expenses':'id,group_id,name,amount,payer,created',
         'shares':'expense_id,member_id,amount','settlements':'id,group_id,sender,receiver,amount,created'}

class Result:
 def __init__(self,rows):self.rows=rows
 def __iter__(self):return iter(self.rows)
 def fetchone(self):return self.rows[0] if self.rows else None

class ScopedConnection:
 def __init__(self,c,user):self.c,self.user=c,user
 def execute(self,sql,args=()):
  if 'sqlite_master' in sql:return Result([{'exists':1}])
  params={f'p{i}':v for i,v in enumerate(args)};parts=sql.split('?')
  sql=''.join(part+(f':p{i}' if i<len(parts)-1 else '') for i,part in enumerate(parts))
  if sql=='SELECT * FROM profile':
   return Result(list(self.c.execute(text('SELECT * FROM split_profiles WHERE id=:u'),{'u':self.user['id']}).mappings()))
  if sql.startswith('UPDATE profile SET'):
   sql=sql.replace('profile','split_profiles')+' WHERE id=:uid';params['uid']=self.user['id']
  created=sql.startswith('INSERT INTO groups ')
  for table,columns in COLUMNS.items():sql=sql.replace('INSERT INTO '+table+' VALUES','INSERT INTO '+table+'('+columns+') VALUES')
  if sql.startswith('SELECT * FROM groups ORDER BY'):
   sql='SELECT g.* FROM split_groups g JOIN split_group_users u ON u.group_id=g.id WHERE u.user_id=:uid ORDER BY g.created_at DESC'
   params['uid']=self.user['id']
  else:
   for table in TABLES:sql=re.sub(r'\b'+table+r'\b','split_'+table,sql)
  result=self.c.execute(text(sql),params)
  if created:
   self.c.execute(text("INSERT INTO split_group_users(group_id,user_id,role) VALUES(:g,:u,'owner')"),{'g':args[0],'u':self.user['id']})
  return Result(list(result.mappings()) if result.returns_rows else [])
 def executemany(self,sql,args):
  for values in args:self.execute(sql,values)


def create_app(identity):
 app=Flask(__name__);app.config['MAX_CONTENT_LENGTH']=32768
 app.register_blueprint(blueprint(identity),url_prefix='/api/auth')
 @app.errorhandler(AuthError)
 def auth_error(e):return jsonify(error=e.code),e.status
 @app.errorhandler(ValueError)
 def bad_request(e):return jsonify(error=str(e)),400
 @app.errorhandler(SQLAlchemyError)
 def database_error(_):return jsonify(error='Unable to save. Please retry.'),503
 @app.get('/health')
 def health():return {'status':'ok','mode':'mysql-identity'}
 @app.route('/api/v1/<path:path>',methods=['GET','POST'])
 def api(path):
  header=request.headers.get('Authorization','')
  user=identity.authenticate(header[7:] if header.startswith('Bearer ') else '')
  with identity.engine.begin() as c:
   # Serialize profile creation for this user; group mutations lock the shared group below.
   identity.lock_user(c,user['id'])
   if not identity.one(c,'SELECT id FROM split_profiles WHERE id=:u',u=user['id']):
    identity.execute(c,'INSERT INTO split_profiles(id,nickname) VALUES(:u,:n)',u=user['id'],n=user['display_name'])
   scoped=ScopedConnection(c,user)
   if request.method=='POST':
    data=request.get_json(silent=True)
    if not isinstance(data,dict):raise ValueError('Invalid request')
    if path.startswith('groups/'):
     group=path.split('/')[1]
     suffix=' FOR UPDATE' if c.dialect.name=='mysql' else ''
     permission=identity.one(c,"SELECT role FROM split_group_users WHERE group_id=:g AND user_id=:u"+suffix,g=group,u=user['id'])
     if not permission or permission['role'] not in ('owner','editor'):raise AuthError('group_not_found',404)
     identity.one(c,'SELECT id FROM split_groups WHERE id=:g'+suffix,g=group)
    mutate(scoped,'/'+path,data)
   elif path!='state':raise AuthError('not_found',404)
   return jsonify(snapshot(scoped))
 return app
