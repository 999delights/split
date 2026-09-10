"""Integration check against an explicitly disposable, initially empty MySQL DB."""
import os
from pathlib import Path
import tempfile
import db
import pymysql

name=os.environ['MYSQL_TEST_DATABASE']
if not name.endswith('_migration_test'):
    raise RuntimeError('Only a disposable *_migration_test database is allowed')
connection=pymysql.connect(host=os.getenv('MYSQL_TEST_HOST','127.0.0.1'),port=int(os.getenv('MYSQL_TEST_PORT','3306')),
 user=os.environ['MYSQL_TEST_USER'],password=os.environ['MYSQL_TEST_PASSWORD'],database=name,
 autocommit=True,cursorclass=pymysql.cursors.DictCursor)
try:
 with connection.cursor() as c:
  c.execute('SELECT COUNT(*) AS n FROM information_schema.tables WHERE table_schema=DATABASE()')
  if c.fetchone()['n'] != 0: raise RuntimeError('Test database must be empty; nothing deleted')
 files=db.migrations()
 if not files:
  files=[('001_fixture','fixture-checksum','CREATE TABLE migration_fixture (id INT PRIMARY KEY) ENGINE=InnoDB;')]
 first=db.execute(connection,'db:migrate',files)
 second=db.execute(connection,'db:migrate',files)
 assert first==second
 assert db.execute(connection,'db:validate',files)['pending']==[]
 altered=[(n,'changed-checksum',s) for n,h,s in files]
 try: db.execute(connection,'db:migrate',altered)
 except ValueError as e: assert 'checksum' in str(e)
 else: raise AssertionError('Changed applied migration accepted')
 print('Empty MySQL baseline, repeat run, validation and checksum rejection passed.')
finally: connection.close()
