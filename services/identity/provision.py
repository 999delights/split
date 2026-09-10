"""Prepare external dev identity files; never deploy, migrate, or print secrets."""
import argparse
import json
import os
from pathlib import Path
import secrets
from urllib.parse import urlparse
from cryptography.fernet import Fernet
from .runtime import load_config


def quote(value):
    value = str(value)
    if any(c in value for c in ('\r', '\n', '\x00')):
        raise ValueError('Multiline configuration values are not supported')
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"


def exclusive(path, value):
    # Mode applies on POSIX; on Windows the runtime directory must already
    # have restricted ACLs. Never rotate or overwrite existing signing keys.
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w', encoding='utf-8') as stream:
        stream.write(value)


def provision(product, config_root, secrets_root, public_url,
              google_ids, apple_ids, sender, recipient, reply_to=None):
    from infra.db.auth_readiness import read_env
    from .core import Identity
    if product not in ('statz', 'bliss', 'sixth', 'split'):
        raise ValueError('Invalid product')
    url = urlparse(public_url)
    if url.scheme != 'https' or not url.hostname or url.username or url.password or url.query or url.fragment or url.path.rstrip('/') != '/api/auth':
        raise ValueError('Public URL must be HTTPS and end in /api/auth')
    if not google_ids or not apple_ids or any(not x.strip() for x in google_ids + apple_ids):
        raise ValueError('Explicit Google and Apple client IDs are required')
    sender, recipient = Identity.email(sender), Identity.email(recipient)
    reply_to = Identity.email(reply_to) if reply_to else sender
    config_root, secrets_root = Path(config_root), Path(secrets_root)
    database = config_root / (product + '.database.env')
    db = read_env(database)
    if db.get('APP_DB_NAME') != 'dev_' + product + '_db':
        raise ValueError('Expected development database configuration')
    paths = [config_root / (product + '.identity.env'),
             secrets_root / (product + '-auth-development.key'),
             secrets_root / (product + '-email-development.key')]
    if any(p.exists() for p in paths):
        raise ValueError('Identity configuration or keys already exist; no files changed')
    if not config_root.is_dir() or not secrets_root.is_dir():
        raise ValueError('Create restricted runtime config and secrets directories first')
    values = dict(APP_ENV='development', AUTH_PUBLIC_URL=public_url.rstrip('/'),
                  AUTH_SECRET_FILE=str(paths[1]), AUTH_EMAIL_KEY_FILE=str(paths[2]),
                  GOOGLE_CLIENT_IDS=','.join(x.strip() for x in google_ids),
                  APPLE_CLIENT_IDS=','.join(x.strip() for x in apple_ids),
                  MAIL_ENABLED='true', SMTP_FROM=sender,
                  SMTP_REPLY_TO=reply_to, SMTP_MESSAGE_DOMAIN=sender.split('@')[1], MAIL_ALLOWLIST=recipient)
    content = ''.join(k + '=' + quote(v) + '\n' for k, v in values.items())
    created = []
    try:
        for path, value in [(paths[1], secrets.token_urlsafe(48)),
                            (paths[2], Fernet.generate_key().decode()), (paths[0], content)]:
            exclusive(path, value)
            created.append(path)
        # Validate using the same parser as runtime; no SQL or SMTP operation.
        identity = load_config(product, paths[0], database)
        identity.engine.dispose()
    except Exception:
        for path in reversed(created):
            path.unlink()
        raise
    return {'product': product, 'configuration': 'prepared', 'activated': False}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--product', required=True, choices=['statz', 'bliss', 'sixth', 'split'])
    parser.add_argument('--config-root', required=True)
    parser.add_argument('--secrets-root', required=True)
    parser.add_argument('--public-url', required=True)
    parser.add_argument('--google-id', action='append', required=True)
    parser.add_argument('--apple-id', action='append', required=True)
    parser.add_argument('--sender', required=True)
    parser.add_argument('--recipient', required=True)
    parser.add_argument('--reply-to')
    args = parser.parse_args()
    try:
        print(json.dumps(provision(args.product, args.config_root, args.secrets_root,
              args.public_url, args.google_id, args.apple_id, args.sender, args.recipient, args.reply_to)))
    except Exception:
        parser.exit(1, 'Identity preparation failed. Existing files preserved; configuration values suppressed.\n')


if __name__ == '__main__':
    main()
