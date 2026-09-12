"""Real MySQL service tests after migrations, on an explicitly disposable CI database."""
import json
import os
from concurrent.futures import ThreadPoolExecutor
from cryptography.fernet import Fernet
from sqlalchemy import create_engine,URL,text
from .core import Identity,AuthError
from .mail import deliver_one


def main():
 name=os.environ['MYSQL_TEST_DATABASE']
 if not name.endswith('_migration_test'):raise RuntimeError('Disposable database required')
 product=os.environ['IDENTITY_TEST_PRODUCT']
 engine=create_engine(URL.create('mysql+pymysql',username=os.environ['MYSQL_TEST_USER'],password=os.environ['MYSQL_TEST_PASSWORD'],host=os.getenv('MYSQL_TEST_HOST','127.0.0.1'),port=int(os.getenv('MYSQL_TEST_PORT','3306')),database=name),isolation_level='READ COMMITTED')
 config={'product':product,'environment':'test','secret':'test-only-key-'*5,'email_key':Fernet.generate_key().decode(),'public_url':'http://localhost','mail_enabled':True,'smtp_from':'test@example.test','message_domain':'example.test','mail_allowlist':['identity@example.test']}
 identity=Identity(engine,config)
 try:
  identity.register('identity@example.test','valid test password','CI User','127.0.0.1')
  with engine.connect() as c:row=identity.one(c,"SELECT payload_encrypted FROM auth_email_outbox WHERE template='email-verification'")
  token=json.loads(identity.cipher.decrypt(row['payload_encrypted'].encode()))['token']
  identity.consume(token,'verify')
  session=identity.login('identity@example.test','valid test password','MySQL CI','127.0.0.1')
  assert identity.authenticate(session['access_token'])['id']==session['user']['id']
  def refresh():
   try:return identity.refresh(session['refresh_token'])
   except AuthError as e:return e.code
  with ThreadPoolExecutor(max_workers=2) as executor:results=list(executor.map(lambda _:refresh(),range(2)))
  assert sum(isinstance(r,dict) for r in results)==1,results
  assert 'session_reuse_detected' in results,results
  descendant=next(r for r in results if isinstance(r,dict))
  try:identity.authenticate(descendant['access_token'])
  except AuthError:pass
  else:raise AssertionError('Refresh replay did not revoke descendant')
  if product=='split':
   from services.backend.mysql_app import create_app
   client=create_app(identity).test_client()
   login=identity.login('identity@example.test','valid test password','domain CI','127.0.0.2')
   headers={'Authorization':'Bearer '+login['access_token']}
   assert client.get('/api/v1/state').status_code==401
   response=client.post('/api/v1/groups',json={'name':'MySQL CI trip'},headers=headers)
   assert response.status_code==200,response.json
   group=response.json['groups'][0];gid=group['id'];member=group['members'][0]['id']
   response=client.post('/api/v1/groups/'+gid+'/expenses',headers=headers,json={'name':'CI expense','amount':100,'payer':member,'shares':{member:100}})
   assert response.status_code==200,response.json
   assert response.json['groups'][0]['balances'][member]==0
   identity.logout(login['user']['id'],login['refresh_token'])
   assert client.get('/api/v1/state',headers=headers).status_code==401
   print('Split domain passed against MySQL: group, expense, balances and revocation.')
  delivered=[]
  assert deliver_one(identity,delivered.append)
  assert delivered
  from .contract_mysql_check import check_contract
  check_contract(identity,session['user']['id'])
  print('MySQL identity passed: verification, login, concurrent refresh replay, revocation and leased outbox.')
 finally:engine.dispose()

if __name__=='__main__':main()
