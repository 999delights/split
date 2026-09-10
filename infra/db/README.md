# MySQL migration commands

Install requirements.txt in a dedicated Python environment. Run `python infra/db/db.py db:status --env-file PATH`, `db:migrate` or `db:validate`. The env file uses the Windows APP_DB_* contract and is never committed. Status/validate use runtime credentials; migrate uses migration credentials.

Migration files are immutable UTF-8/LF SQL, numbered 001_name.sql. A checksum ledger and database-scoped lock protect reruns. Existing incompatible ledgers are refused: no automatic adoption or replay. Empty baselines also refuse initialization. MySQL DDL implicitly commits: a failed migration requires inspection, not blind rollback claims. `checks/*.sql` must return rows with violations=0.

Before deployment: baseline backup, migrate, validate, isolated tests, then PM2 restart. Do not enable deployment integration until a product baseline and fresh-MySQL integration test are approved and passing. This framework alone does not migrate application reads/writes or identities.
