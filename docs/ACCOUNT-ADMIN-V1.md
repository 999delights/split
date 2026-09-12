# Accounts and email templates — Admin contract v1 (DEV)

Implemented in all four product repositories on dev. Each product owns its own users,
provider identities, password credentials, sessions, devices and mail outbox. No
cross-product email merge, domain import, legacy deletion, or Admin repository change.

| Product | Database | Public DEV API | Admin prefix | Additive migration |
| --- | --- | --- | --- | --- |
| STATZ | dev_statz_db | https://statz-api.dddcreate.com | /api/admin/v1/statz | 008_account_admin_contract |
| Bliss | dev_bliss_db | https://bliss-api.dddcreate.com | /api/admin/v1/bliss | 007_account_admin_contract |
| Sixth | dev_sixth_db | https://sixth.dddcreate.com | /api/admin/v1/sixth | 002_account_admin_contract |
| Split | dev_split_db | https://split-api.dddcreate.com | /api/admin/v1/split | 004_account_admin_contract |

## Windows / Admin authentication

The app identity config file accepts two optional paths:

- AUTH_ADMIN_READ_TOKEN_FILE
- AUTH_ADMIN_WRITE_TOKEN_FILE

Create separate, random credentials of at least 32 characters for EACH product and
scope in protected external Windows files. Do not reuse application signing keys or
SMTP credentials. Only the Admin backend receives these credentials; never its
browser/frontend. An absent/unreadable file denies Admin requests (401) and does
not prevent ordinary app authentication. No secret file/content belongs in Git.
Existing PRODUCT_ADMIN_READ_TOKEN / PRODUCT_ADMIN_WRITE_TOKEN process environment
variables remain a fallback when the corresponding file path is absent (including
BLISS_ADMIN_READ_TOKEN compatibility). File paths take precedence.

Send `Authorization: Bearer <service credential>`. GET and POST preview use the read
credential; PATCH uses the write credential. Existing application user tokens are
not Admin credentials. Admin must enforce its own employee roles and inject the
logged-in admin's actor identifier on template writes. Credentials are per product;
do not configure one shared value for all products.

The existing DEV push workflow runs tests and disposable MySQL checks before Windows
deployment. STATZ, Bliss and Sixth perform backup and incremental migrations through
their existing deployment scripts. Split deliberately retains its explicit migration
gate: the automatic push run stops at pending migration 004; Windows must run
workflow_dispatch with apply_migrations=true to back up, apply and deploy it.
Mac does not run migrations against Windows or issue PM2 commands. Configure token paths on Windows
and apply its ordinary controlled config reload; do not change staging or production.
Sixth proxies the allowlisted Admin routes to its existing loopback identity sidecar.
No new ports, public hosts or database credentials are needed.

## Read endpoints (append to product Admin prefix)

- GET /contract — version, product/environment, provider configuration flags and caveats.
- GET /users?limit=50&offset=0&q=... — accounts with login methods, has_password,
  primary email verification/source, last_login_at/provider and active_sessions.
- GET /users/{id} — account plus identities, email_addresses, devices, and first
  50 session families (sessions_total). Bliss retains the sanitized agents field.
- GET /users/{id}/sessions?limit=50&offset=0 — paginated login families.
- GET /users/{id}/events?limit=50&offset=0 — security event type/provider/time.
- GET /email-outbox?user_id={id}&limit=50&offset=0 — sanitized delivery metadata.
- GET /email-templates — five effective templates and capabilities.
- GET /email-templates/{key}/revisions?limit=50&offset=0 — saved text and audit actor.

Pagination limits 1–100. Timestamps are ISO-8601 UTC; absent history remains null.
Existing DATETIME columns are interpreted as UTC, consistent with identity timestamps;
Windows should confirm its database timezone when auditing older created_at values.
Public UUID field is always `id` even though STATZ stores app_users.user_id.

`login_methods` lists actual google/apple identities and email only when an
`auth_passwords` credential exists. A Google email alone does NOT mean password login
exists. `verified_at`/`verification_source` describe provider or email verification;
new `confirmed_at` specifically records a successful confirmation link. Historical
rows are not assigned a fabricated confirmation time. Identities without recorded
verification/time metadata remain unknown until the relevant login updates them.

`last_login_at` and `last_login_provider` are written only on login, not refresh.
For old rows lacking last_login_provider, the original session family can supply it;
missing timestamps remain null. Each session family appears once across token
rotation. Status: active, expired, revoked, rotated, or account_disabled. Active is
not online presence. Old device labels are retained without inventing a physical ID.
Devices expose id, platform, name, model, app_version, created_at, last_seen_at,
revoked_at. last_seen_at is device login/refresh activity, not a live heartbeat.
Mobile installations send their persisted random identifier at login and refresh;
this enriches old sessions when the updated build next refreshes. It is a label for
an installation, NOT hardware attestation. Never group devices only by model/name.
No passwords, hashes, provider subjects, refresh tokens, action tokens, installation
IDs, ciphertext payloads or local agent secrets are exposed by this contract.

Outbox: recipient, template, status, attempts, next_attempt_at, created_at, sent_at,
error_code. `sent` means SMTP accepted the message, not inbox delivery/opening.
No real email is sent by the Admin read or preview endpoints.

## Backend-owned branded templates connected to the actual mail worker

Keys: welcome, email-verification, password-reset, password-changed, identity-linked,
security-alert. The first five have active application triggers. security-alert remains explicitly
marked reserved / automatically_triggered=false; no delivery claim for this template.

POST /email-templates/{key}/preview
JSON: {} for the saved/default template, or {"subject":"Welcome {{app_name}}",
"body":"Your account is ready."}. Returns preview.subject/text/html, sends_email=false.
Verification/reset previews use a non-functional preview.invalid URL.

PATCH /email-templates/{key}
JSON: {"subject":"Welcome {{app_name}}","body":"Your account is ready.",
"expected_revision":0,"actor":"admin-user-id"}
Returns the saved template. Revision 0 means the code default. Subsequent writes
must match the latest revision; stale edits fail 409. Each saved version has an
audit record. Restore by submitting previous content with the CURRENT expected_revision.
Templates are stored only inside that product/environment database.

Subject/body are TEXT, not arbitrary HTML. Optional variables are {{app_name}} and {{display_name}}; identity-linked also
accepts {{provider}} (Google, Apple, or Email and password). The variables array
in each template response advertises these additions; existing app_name-only
content remains valid. Preview uses a fictional Alex and Google, never account data.
Unknown placeholders, empty/oversized fields and newline headers are rejected.
HTML is generated with escaping. Verification/reset URLs are always constructed by
the backend and appended separately: template editing cannot remove or change the
security token, purpose, destination or lifetime. Subject includes the app brand and
non-production environment prefix. The SMTP worker resolves the effective template
at send time, so edits affect unsent/retrying messages as well as future messages.
Brand sender and Reply-To remain external settings, not editable in this endpoint.

The six code defaults and palette live in services/identity/email_brand.py; the
responsive, inline-styled table layout is rendered by email_layout.py. Plain text
and HTML use the same effective copy and context. No remote images, fonts, scripts
or tracking are loaded. Existing database overrides and revision history are kept;
a render/list/preview never writes a revision. The new identity-linked key is a
code default at revision 0, supported by the existing VARCHAR key columns.
No schema migration, template seed/overwrite, or retrospective notification is needed.
Admin uses its existing Email Templates → Applications page; no new editor is required.

SMTP continues using contact@dddcreate.com and app-specific Reply-To aliases. No
changes to website email settings, allowlists, or production sending were made.

## Application methods

All products now expose authenticated POST /api/auth/methods,
POST /api/auth/link/google {id_token}, /link/apple {id_token,nonce},
/link/email {email,password}. Google/Apple linking requires a fresh verified provider
proof; Apple requires the single-use /challenge nonce. Matching an email never
silently merges accounts. Existing provider ownership cannot be taken by another
account. Email-password linking activates only after the confirmation link is consumed.
No second welcome is enqueued for an already welcomed social account.
identity-linked is queued transactionally only for a new explicit Google/Apple
association or successful email-password confirmation, not for ordinary login,
registration, failed proof, or a repeated linking request. The unique outbox key
deduplicates each identity; social subjects are hashed in that key. Email linking
uses one stable key for the account password credential. The primary verified
account email is preferred; otherwise an existing verified address is selected.
If there is no verified address, no email is queued and no recipient is invented.
Failures roll back both the new link and its queued notification. security-alert
remains reserved without any automatic enqueue path.
POST /api/auth/refresh also accepts optional structured device metadata. Existing
string-only clients remain compatible. A known session cannot be moved to another
installation ID during refresh. Refresh metadata does not change last login time.

Bliss already has the UI for linking methods. The other mobile apps now collect
structured device data; their complete linking screen/Apple and email end-to-end
review remains a separate step. Configured Apple audiences and successful builds
are not proof of Apple consent working. Android Apple web setup is still separate.

## Validation / handoff

Unit coverage: unauthenticated/cross-scope Admin access, same-account provider linking,
Apple nonce replay, email proof, stable device/refresh/revocation, legacy enrichment,
expired sessions, no secret exposure, template validation/revision/actual mail worker.
MySQL CI: immutable migrations on empty DB, repeat/checksums, refresh concurrency,
real device/session foreign keys, Admin reads and concurrent template writes.
Flutter: existing tests plus metadata serialization/persistence and refresh tests.

Windows AI: configure per-product service-token files; use the deployed v1 endpoints
for Users and Email Templates. Check /contract and endpoint authorization before
wiring Admin. Test previews first. Report concrete missing data from actual DEV rows;
do not mutate accounts or merge users to make the UI look complete. App users must
use an updated mobile build and login/refresh to populate new device metadata.

## Branded email validation (DEV)

Run `python -m unittest services.identity.test_email_templates
services.identity.test_account_contract` (on one command line). Tests use disposable
fixtures and intercepted senders; they do not call SMTP. CI also checks transactional
identity-linked deduplication and rollback on a fresh MySQL database.

Preview every key with the existing read-only service credential. Confirmation and
reset previews contain only https://preview.invalid/confirmation and sends_email=false.
Template source, preview, history and logs never contain real action tokens or account
credentials. At delivery, the existing worker alone generates the one-time action URL
from AUTH_PUBLIC_URL; the opaque token is confined to the URL fragment (not visible
HTML text, query parameters or a template variable). Only that backend-owned URL can
be rendered as a verification/reset CTA. Do not log or persist rendered real messages.

No live registration, reset or linking request is needed to validate these designs.
Keep SMTP secrets, per-app Reply-To, DEV allowlists and runtime controls on Windows.
A DEV code push uses the existing workflow; staging and production are untouched.
