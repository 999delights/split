"""Only synthetic SQLite unit-test fixture extensions; never a runtime migration."""
from sqlalchemy import inspect,text

def extend_fixture(engine,product):
 with engine.begin() as c:
  def add(table,name,kind):
   if name not in {x['name'] for x in inspect(c).get_columns(table)}:c.execute(text(f'ALTER TABLE {table} ADD COLUMN {name} {kind}'))
  add('app_users','last_login_provider','TEXT');add('app_users','last_login_at','TEXT');add('app_users','created_at','TEXT')
  add('auth_identities','created_at','TEXT');add('auth_identities','last_login_at','TEXT');add('auth_identities','email_verified','INTEGER')
  add('auth_email_addresses','confirmed_at','BIGINT');add('auth_sessions','device_id','TEXT');add('auth_actions','pending_password_hash','TEXT')
  c.execute(text('CREATE TABLE IF NOT EXISTS user_devices(id TEXT PRIMARY KEY,user_id TEXT,installation_id TEXT,platform TEXT,name TEXT,model TEXT,app_version TEXT,created_at TEXT DEFAULT CURRENT_TIMESTAMP,last_seen_at TEXT,revoked_at TEXT,UNIQUE(user_id,installation_id))'))
  c.execute(text('CREATE TABLE auth_email_templates(template_key TEXT PRIMARY KEY,subject TEXT,body TEXT,revision INTEGER,updated_at BIGINT)'))
  c.execute(text('CREATE TABLE auth_template_revisions(id INTEGER PRIMARY KEY AUTOINCREMENT,template_key TEXT,revision INTEGER,subject TEXT,body TEXT,updated_at BIGINT,actor TEXT,UNIQUE(template_key,revision))'))
