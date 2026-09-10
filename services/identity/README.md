# Application identity implementation — integration in progress

This directory is an identical, versioned identity component owned by this product.
It uses the product's app_users/auth_identities and additive auth_* tables; it has
no Firebase dependency and no shared cross-product database. Existing production
login routes are not switched by adding these files.

## Implemented
- Provider token verification (Google/Apple RS256, issuer/audience/expiry, Apple nonce).
- Provider+subject account lookup; matching email never silently attaches a provider.
- Argon2 password registration/login with required email confirmation.
- Hashed expiring single-use action tokens; encrypted durable mail payloads.
- 10-minute access JWT, hashed rotating refresh sessions, family revocation on reuse.
- Device/global logout, status enforcement and product/environment token isolation.
- SMTP outbox, leases/retries, environment allowlist, HTML+text templates and a
  manual-submit confirmation/reset landing page (no action during mail-scanner GET).
- Flutter client/screen in lib/identity with Keychain/Keystore refresh storage.

## Not yet activated or complete
- Runtime SMTP and Google/Apple application configuration are required externally.
- Product-domain authorization adapters and preserved-data account linking are not
  complete. The new screen must not be made the default before these pass tests.
- Explicit provider linking, change-email, role administration and legacy session
  migration are not implemented. A collision asks for existing-account sign-in;
  it does not perform an insecure automatic merge.
- Existing Firebase/legacy app code has not been removed; this new component does
  not import it. No claim that all product dependencies are removed yet.
- SMTP provides at-least-once delivery: deterministic Message-ID mitigates but
  cannot guarantee no duplicate delivery after a crash between SMTP and DB commit.
- Rate-limit IPs currently come from the direct connection. A loopback proxy must
  implement trusted original-client addressing before public activation.
- Expired challenge/rate/action retention needs a scheduled bounded cleanup before
  public activation.

## Windows runtime
Use identity.env.example as a template, storing real configuration outside Git.
AUTH_SECRET_FILE is random signing material (>=32 characters); AUTH_EMAIL_KEY_FILE
contains a Fernet key. Do not reuse keys across products/environments. Existing
STATZ JWT issuer/audience compatibility needs explicit cutover configuration.

The database file uses APP_DB_HOST/PORT/NAME/USER/PASSWORD, never migration credentials.
Run schema migrations separately through infra/db/db.py after a verified backup.

    python -m services.identity.runtime --product PRODUCT --env-file PATH --database-file PATH --port PORT --check

Remove --check to start the loopback-only Waitress process and SMTP worker.
Mount/proxy /api/auth on the product API; do not expose this loopback port publicly.
Do not start from PM2 until configuration, migrations and domain adapters are ready.

## Tests

    python -m unittest services.identity.test_identity services.identity.test_http -v

Tests use synthetic SQLite fixtures. CI separately tests actual MySQL migrations.
Real Google/Apple consent and email delivery still require end-to-end verification.
The old 001–004 STATZ SQL is immutable; 005 cleanup remains on its separate review
branch, unapplied. Authentication starts at 006 without silently applying cleanup.
