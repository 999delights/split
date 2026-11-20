# Split Windows DEV deployment

Runtime: `python -m services.identity.runtime --product split`, served by Waitress on 127.0.0.1. The application factory is `services.backend.mysql_app.create_app`: auth at `/api/auth/*`, authenticated domain routes at `/api/v1/*`, and database-aware `/health` (200 with status ok/mode mysql-identity, 503 if database unavailable).

PM2: `split-server`. Checkout: `SPLIT_DEV_ROOT`, branch dev. Dedicated venv: `<TD_RUNTIME_ROOT>\venvs\development\split`.

Machine layout comes from environment variables, so the folders can move without code changes:
- `SPLIT_DEV_ROOT`: the dev checkout (default `D:\apps\split\dev`).
- `TD_RUNTIME_ROOT`: config, tools and venvs outside Git (default `D:\runtime`).
- `TD_DATA_TRANSFER_ROOT`: one-time legacy imports (default `D:\network_share\apps\data-transfer`).

The paths below show the defaults.

External files, never committed:
- `D:\secrets\development\split\split.database.env` (APP_DB_*; APP_DB_NAME must be dev_split_db)
- `D:\secrets\development\split\split.identity.env` (see services/identity/identity.env.example; APP_ENV must be development; referenced secret/key files must exist)
- SMTP imported by `D:\runtime\tools\import_smtp_env.ps1 -Environment development`; five SMTP_* variables passed explicitly to PM2.

## First deployment decision

No Windows port or public URL is established in this repository. Existing local prototype ports are not Windows assignments. Windows must confirm a free loopback port and the intended HTTPS route/AUTH_PUBLIC_URL, with its proxy configuration. Then set repository variable `SPLIT_DEV_PORT` to the confirmed port. This enables automatic deployment on the next matching dev push; a manual workflow can alternatively supply `port`. No placeholder port/URL is assumed. Keep the variable unset until the external configuration is ready.

Pushes touching backend, identity, DB, Windows/PM2 infrastructure, root requirements, or the deployment/database workflow run the reusable database checks. Without a confirmed port the deploy job is skipped. Mobile/docs-only changes do not trigger deployment. Manual workflow_dispatch remains; non-dev runs are skipped. Concurrency never cancels a running deployment.

Checks run on isolated CI MySQL, including fresh/repeated migrations and identity concurrency. The Windows script verifies dev, a clean checkout, and the exact tested commit, installs dependencies, validates external config and runs tests before touching the application database. Automatic deployments back up dev_split_db, apply incremental migrations and validate checksums. Manual runs may disable migration application and will then fail validation if migrations remain pending. PM2 startOrRestart uses --update-env. Local health must pass before pm2 save. A failed health check reports failure and does not save the process list; no automatic schema rollback is attempted.

The authentication/domain implementation and migrations 001/002 are adopted unchanged from the existing auth work branch, except for the database-aware health check. Existing SQLite/Firebase source data is not imported, modified or deleted by this deployment.
