"""Validate development configuration without connecting or changing a database."""
import argparse
from dotenv import dotenv_values
from .runtime import load_config


def check(env_file, database_file):
    if dotenv_values(env_file).get('APP_ENV') != 'development':
        raise ValueError('Only development deployment is allowed')
    identity = load_config('split', env_file, database_file)
    identity.engine.dispose()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--env-file', required=True)
    parser.add_argument('--database-file', required=True)
    args = parser.parse_args()
    try:
        check(args.env_file, args.database_file)
    except Exception:
        parser.exit(1, 'Development configuration invalid or incomplete; values suppressed.\n')
    print('Development configuration validated; no database changes made.')


if __name__ == '__main__':
    main()
