"""Versioned MySQL migration CLI. Never logs configuration or SQL values."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent

def migrations():
    result = []
    for path in sorted((ROOT / 'migrations').glob('*.sql')):
        if not re.fullmatch(r'\d{3,}_[a-z0-9_]+\.sql', path.name):
            raise ValueError('Invalid migration filename')
        raw = path.read_bytes()
        if b'\r' in raw:
            raise ValueError('Migration files must have LF line endings')
        result.append((path.stem, hashlib.sha256(raw).hexdigest(), raw.decode('utf-8')))
    versions = [name.split('_')[0] for name, _, _ in result]
    if len(versions) != len(set(versions)):
        raise ValueError('Duplicate migration version')
    return result

def reconcile(files, applied):
    known = {name: checksum for name, checksum, _ in files}
    for name, checksum in applied.items():
        if name not in known:
            raise ValueError('Database contains an unadopted migration: ' + name)
        if not checksum or known[name] != checksum:
            raise ValueError('Migration checksum mismatch: ' + name)
    return [item for item in files if item[0] not in applied]

def execute(connection, command, files):
    # One named lock for all repos/versions targeting the same database.
    with connection.cursor() as c:
        c.execute('SELECT DATABASE() AS db')
        database = c.fetchone()['db']
        lock = 'app-migrate-' + hashlib.sha256(database.encode()).hexdigest()[:40]
        c.execute('SELECT GET_LOCK(%s, 30) AS acquired', (lock,))
        if c.fetchone()['acquired'] != 1:
            raise ValueError('Another database operation holds the migration lock')
        try:
            c.execute("SELECT column_name FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='schema_migrations'")
            columns = {row['COLUMN_NAME'] if 'COLUMN_NAME' in row else row['column_name'] for row in c.fetchall()}
            if columns and not {'version', 'checksum', 'applied_at'} <= columns:
                raise ValueError('Legacy migration ledger detected. Explicit baseline adoption required; nothing reapplied.')
            if not columns:
                c.execute("SELECT COUNT(*) AS n FROM information_schema.tables WHERE table_schema=DATABASE()")
                if c.fetchone()['n']:
                    raise ValueError('Existing schema has no compatible migration ledger; explicit adoption required')
                if command != 'db:migrate':
                    if command == 'db:validate':
                        raise ValueError('Database has no migration ledger')
                    return {'applied': [], 'pending': [f[0] for f in files]}
                if not files:
                    raise ValueError('No baseline migrations supplied; refusing to initialize database')
                c.execute('CREATE TABLE schema_migrations (version VARCHAR(191) PRIMARY KEY, checksum CHAR(64) NOT NULL, applied_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)) ENGINE=InnoDB')
            c.execute('SELECT version,checksum FROM schema_migrations ORDER BY version')
            applied = {r['version']: r['checksum'] for r in c.fetchall()}
            pending = reconcile(files, applied)
            if command == 'db:migrate':
                import sqlparse
                for name, checksum, sql in pending:
                    connection.begin()
                    try:
                        for statement in sqlparse.split(sql):
                            if statement.strip(): c.execute(statement)
                        c.execute('INSERT INTO schema_migrations(version,checksum) VALUES(%s,%s)', (name, checksum))
                        connection.commit()
                        applied[name] = checksum
                    except Exception:
                        connection.rollback()
                        # MySQL DDL commits implicitly. No false atomicity promise.
                        raise ValueError('Migration failed: ' + name + '. DDL may have committed; inspect before retry.') from None
                pending = []
            if command == 'db:validate':
                if pending: raise ValueError('Pending migrations prevent validation')
                import sqlparse
                for path in sorted((ROOT / 'checks').glob('*.sql')):
                    for statement in sqlparse.split(path.read_text()):
                        c.execute(statement)
                        for row in c.fetchall():
                            if row.get('violations') != 0:
                                raise ValueError('Schema/data validation failed: ' + path.name)
            return {'applied': list(applied), 'pending': [f[0] for f in pending]}
        finally:
            c.execute('SELECT RELEASE_LOCK(%s)', (lock,))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['db:migrate', 'db:status', 'db:validate'])
    parser.add_argument('--env-file', required=True)
    args = parser.parse_args()
    from dotenv import dotenv_values
    import pymysql
    config = dotenv_values(args.env_file)
    if config.get('APP_DB_ENGINE', '').lower() != 'mysql':
        raise ValueError('APP_DB_ENGINE must be mysql')
    migrating = args.command == 'db:migrate'
    keys = ['APP_DB_HOST', 'APP_DB_PORT', 'APP_DB_NAME',
            'APP_DB_MIGRATION_USER' if migrating else 'APP_DB_USER',
            'APP_DB_MIGRATION_PASSWORD' if migrating else 'APP_DB_PASSWORD']
    if any(not config.get(k) for k in keys): raise ValueError('Database configuration incomplete')
    connection = pymysql.connect(host=config[keys[0]], port=int(config[keys[1]]), database=config[keys[2]],
        user=config[keys[3]], password=config[keys[4]], charset='utf8mb4', autocommit=True,
        connect_timeout=10, read_timeout=60, write_timeout=60, cursorclass=pymysql.cursors.DictCursor)
    try: result = execute(connection, args.command, migrations())
    finally: connection.close()
    print(json.dumps(result))
    if os.getenv('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8') as f:
            f.write('\n### ' + args.command + '\n\n' + str(len(result['applied'])) + ' applied; ' + str(len(result['pending'])) + ' pending.\n')

if __name__ == '__main__':
    try: main()
    except ValueError as e:
        print(str(e), file=sys.stderr); sys.exit(1)
    except Exception:
        print('Database operation failed; check connectivity, grants and server diagnostics. Secrets suppressed.', file=sys.stderr); sys.exit(1)
