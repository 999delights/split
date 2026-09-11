# Split DEV backend

Python/Waitress runs `services.identity.runtime --product split`; it mounts
Google/email/Apple identity at `/api/auth` and the authenticated MySQL Split API
at `/api/v1`. No Firebase Auth or legacy preview token is used in this runtime.
`GET /health` checks MySQL and returns `status`, `mode=mysql-identity`, `commit`.

## Windows contract

- Branch: dev, repository 999delights/split.
- Requested runtime checkout: `D:\network_share\apps\development\split`.
  Windows confirmed the spelling with `network\_share` does not exist. Preserve
  the existing checkout; no automated relocation or deletion is performed.
- PM2: split-server, loopback port **3400** (deployment checks port ownership).
- Virtualenv: `D:\app-runtime\venvs\development\split`.
- Config: `D:\app-runtime\config\development\split.database.env` and
  `split.identity.env` (template: services/identity/split.identity.env.example).
- MySQL must be `dev_split_db`; APP_DB_* includes separate migration credentials.
- SMTP injected using `D:\app-runtime\tools\import_smtp_env.ps1 -Environment development`.
  All five SMTP variables are explicitly forwarded to PM2, never logged.
- Signing/email keys remain in the external development secrets directory with
  restrictive Windows ACLs. Existing provision.py can generate fresh keys locally
  and refuses to overwrite existing configuration/keys.

Windows still needs to supply the public HTTPS hostname, Split Google Web client
ID and mobile iOS/Android client IDs. The example has no invented OAuth IDs or
secrets. Set one Web client ID in GOOGLE_CLIENT_IDS; native ID tokens are verified
against Google RS256/JWKS, issuer, audience, expiry and verified email. Repeated
provider+subject resolves the same user. Existing email does not silently merge
accounts. Refresh rotates hashed tokens; reuse and logout revoke sessions.

## Baseline and first deployment

The immutable existing migrations are:
1. `001_application_authentication.sql`: users, providers, verified addresses,
   password credentials, sessions, email/reset actions, challenges, throttling,
   encrypted mail outbox and security events.
2. `002_split_domain.sql`: profiles, groups, roles, members, expenses, shares,
   settlements, metadata and import ledger. No import is performed.

Windows preparation:
1. Preserve the old checkout and any local changes. Verify origin is this repo;
   prepare a clean dev checkout at the chosen runtime path. Deployment refuses
   wrong remotes, dirty trees, other branches or an unexpected commit.
2. Inject external database/identity/SMTP configuration and keys. Confirm 3400 is free.
3. Configure the chosen HTTPS route to `http://127.0.0.1:3400` without browser-only
   access challenges on mobile API endpoints. The hostname is still undecided.
4. Run the dev deploy workflow manually with port 3400 and apply_migrations=true
   only when Windows is ready to apply the baseline. Backup runs before migrations.
5. Confirm `/health`, exact commit, unauthorized `/api/auth/me` and `/api/v1/state`
   return 401, then test Google from the mobile app once its IDs are supplied.

Push dev automatically runs fresh MySQL checks before Windows deploy for backend,
identity, database and deployment files. Mobile/docs-only pushes do not deploy.
**Push does not apply pending migrations**: Windows explicitly applies them or
uses the manual workflow option above. Missing secrets or pending migrations
stop deployment. Existing databases are never recreated; ledger/checksum guards
make migration reruns safe. No data import or deletion, Admin/staging/prod changes.
PM2 restarts with --update-env and saves only after successful health verification.
