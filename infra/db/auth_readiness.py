"""Read-only Windows auth preflight. Reports names/status, never config values."""
import argparse
import contextlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys

PRODUCTS = ('statz', 'bliss', 'sixth', 'split')
REQUIRED = ('APP_ENV', 'AUTH_PUBLIC_URL', 'AUTH_SECRET_FILE',
            'AUTH_EMAIL_KEY_FILE', 'GOOGLE_CLIENT_IDS', 'APPLE_CLIENT_IDS',
            'SMTP_HOST', 'SMTP_USER', 'SMTP_PASSWORD', 'SMTP_FROM',
            'SMTP_MESSAGE_DOMAIN', 'MAIL_ALLOWLIST')


def read_env(path):
    from dotenv import dotenv_values
    # Malformed dotenv warnings can contain source lines. Suppress them too.
    with contextlib.redirect_stderr(io.StringIO()):
        return dotenv_values(path) if path.is_file() else {}


def inspect(product, root):
    database = root / (product + '.database.env')
    identity = root / (product + '.identity.env')
    # Existing service config may explicitly select a differently named file.
    for name in (product + '.env', product + '-agent.env'):
        configured = read_env(root / name).get('APP_IDENTITY_ENV_FILE')
        if configured:
            candidate = Path(configured)
            if candidate.is_absolute():
                identity = candidate
                break
    config = read_env(identity)
    for key in ('SMTP_HOST', 'SMTP_PORT', 'SMTP_SECURITY', 'SMTP_USER', 'SMTP_PASSWORD'):
        config[key] = os.environ.get(key)
    db = read_env(database)
    report = {'product': product, 'identity_file_present': identity.is_file(),
              'database_file_present': database.is_file(),
              'missing_settings': [key for key in REQUIRED if not config.get(key)],
              'environment_matches': config.get('APP_ENV') == 'development',
              'database_matches': db.get('APP_DB_NAME') == 'dev_' + product + '_db',
              'mail_enabled': config.get('MAIL_ENABLED') == 'true',
              'secret_files_readable': {}}
    for name in ('AUTH_SECRET_FILE', 'AUTH_EMAIL_KEY_FILE'):
        try:
            path = Path(config.get(name) or '')
            report['secret_files_readable'][name] = path.is_file() and bool(path.read_bytes().strip())
        except OSError:
            report['secret_files_readable'][name] = False
    report['database_status'] = 'not_checked'
    if database.is_file() and report['database_matches']:
        try:
            result = subprocess.run([sys.executable, str(Path(__file__).with_name('db.py')),
                                     'db:status', '--env-file', str(database)],
                                    capture_output=True, text=True, timeout=90)
            if result.returncode == 0:
                status = json.loads(result.stdout)
                # Return counts only: subprocess errors/config values never escape.
                report['database_status'] = 'reachable'
                report['applied_count'] = len(status.get('applied', []))
                report['pending_count'] = len(status.get('pending', []))
            else:
                report['database_status'] = 'check_failed'
        except (OSError, ValueError, subprocess.TimeoutExpired):
            report['database_status'] = 'check_failed'
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--product', choices=PRODUCTS, required=True)
    parser.add_argument('--config-root', default=r'D:\app-runtime\config\development')
    args = parser.parse_args()
    try:
        report = inspect(args.product, Path(args.config_root))
    except Exception:
        report = {'product': args.product, 'preflight': 'failed',
                  'detail': 'Configuration could not be inspected; values suppressed.'}
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
