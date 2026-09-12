"""Standalone loopback service; reverse proxy /api/auth to it per product."""
import argparse
import json
import os
import threading
import time
from pathlib import Path
from flask import Flask
from sqlalchemy import create_engine, URL
from dotenv import dotenv_values
from .core import Identity
from .http_api import blueprint
from .mail import deliver_one


def load_config(product, env_file, database_file):
    values={**dotenv_values(env_file)}
    db=dotenv_values(database_file)
    environment=values.get('APP_ENV','development')
    prefixes={'development':'dev_','staging':'staging_','production':''}
    expected_database=prefixes.get(environment,'')+product+'_db'
    if environment not in prefixes or db.get('APP_DB_NAME')!=expected_database:
        raise ValueError('Product/environment/database mismatch')
    def required(key):
        value=values.get(key)
        if not value:raise ValueError('Missing configuration: '+key)
        return value
    def smtp_required(key):
        value = os.environ.get(key)
        if not value: raise ValueError('Missing SMTP environment variable: ' + key)
        return value
    if os.environ.get('SMTP_SECURITY', 'starttls') not in ('ssl', 'starttls'):
        raise ValueError('SMTP must use verified TLS')
    if not 1 <= int(os.environ.get('SMTP_PORT', '587')) <= 65535:
        raise ValueError('Invalid SMTP port')
    google_ids=[v.strip() for v in values.get('GOOGLE_CLIENT_IDS','').split(',') if v.strip()]
    if product=='split' and environment=='development' and (len(google_ids)!=1 or not google_ids[0].endswith('.apps.googleusercontent.com')):
        raise ValueError('Configure exactly one Split DEV Google Web audience')
    secret=Path(required('AUTH_SECRET_FILE')).read_text().strip()
    key=Path(required('AUTH_EMAIL_KEY_FILE')).read_text().strip()
    config={'product':product,'environment':environment,'secret':secret,'email_key':key,
        'admin_read_token_file':values.get('AUTH_ADMIN_READ_TOKEN_FILE'),
        'admin_write_token_file':values.get('AUTH_ADMIN_WRITE_TOKEN_FILE'),
        'public_url':required('AUTH_PUBLIC_URL'),'google_client_ids':google_ids,
        'apple_client_ids':[x.strip() for x in values.get('APPLE_CLIENT_IDS','').split(',') if x.strip()],
        'mail_enabled':values.get('MAIL_ENABLED')=='true','smtp_from':required('SMTP_FROM'),
        'smtp_reply_to':Identity.email(values['SMTP_REPLY_TO']) if values.get('SMTP_REPLY_TO') else None,
        'message_domain':required('SMTP_MESSAGE_DOMAIN'),'smtp_host':smtp_required('SMTP_HOST'),
        'smtp_port':os.environ.get('SMTP_PORT','587'),'smtp_security':os.environ.get('SMTP_SECURITY','starttls'),'smtp_user':smtp_required('SMTP_USER'),
        'smtp_password':smtp_required('SMTP_PASSWORD'),
        'mail_allowlist':[x.strip().lower() for x in values.get('MAIL_ALLOWLIST','').split(',') if x.strip()]}
    if environment!='production' and not config['mail_allowlist']:raise ValueError('MAIL_ALLOWLIST required outside production')
    engine=create_engine(URL.create('mysql+pymysql',username=db['APP_DB_USER'],password=db['APP_DB_PASSWORD'],
        host=db['APP_DB_HOST'],port=int(db['APP_DB_PORT']),database=db['APP_DB_NAME']),pool_pre_ping=True,isolation_level='READ COMMITTED',
        connect_args={'connect_timeout':10,'read_timeout':15,'write_timeout':15})
    return Identity(engine,config)


def start_mail_worker(identity):
    def worker():
        while True:
            try:worked=deliver_one(identity)
            except Exception:worked=False
            time.sleep(.5 if worked else 5)
    threading.Thread(target=worker,daemon=True).start()

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--product',required=True,choices=['statz','bliss','sixth','split'])
    parser.add_argument('--env-file',required=True)
    parser.add_argument('--database-file',required=True)
    parser.add_argument('--port',type=int,required=True)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    identity=load_config(args.product,args.env_file,args.database_file)
    if args.check:
        with identity.engine.connect() as c:identity.one(c,'SELECT COUNT(*) AS n FROM auth_sessions')
        print(json.dumps({'product':args.product,'configuration':'ready','database':'reachable'}));return
    from services.backend.mysql_app import create_app
    app=create_app(identity)
    start_mail_worker(identity)
    from waitress import serve
    serve(app,host='127.0.0.1',port=args.port,threads=8)

if __name__=='__main__':main()
