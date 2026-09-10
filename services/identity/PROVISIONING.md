# Development identity provisioning

Windows owns SMTP secrets outside Git:
- Development: `D:\app-runtime\secrets\development\dddcreate.smtp.env`
- Staging: `D:\app-runtime\secrets\staging\dddcreate.smtp.env`

Deploy infrastructure injects SMTP_HOST, SMTP_PORT, SMTP_USER and SMTP_PASSWORD into each backend process. SMTP_SECURITY is `ssl` for implicit TLS (typically 465), or `starttls` (typically 587); default is starttls. The runtime reads these values from the process environment only. It does not read the site's MAIL_* source or copy SMTP credentials into per-product files. Staging is documented only; no staging migration or deployment is enabled here.

`python -m services.identity.provision` prepares external development identity configuration and independent keys. It does not deploy, migrate, or send mail. Required arguments: --product, --config-root, --secrets-root, --public-url, --google-id (repeatable), --apple-id (repeatable), --sender, --recipient. Optional --reply-to selects the product alias.

Run from the repository root with identity requirements installed and the SMTP variables already injected. Configuration and secrets directories must exist with restrictive Windows ACLs for the runtime/deployment account and administrators. Existing files are refused, never overwritten. Config root must contain the matching `<product>.database.env` for `dev_<product>_db`. Generated keys are independent per application. Runtime parsing is checked without making network connections.

Use contact@dddcreate.com as SMTP_FROM; use the product alias only as SMTP_REPLY_TO. Display name is STATZ, Bliss, Sixth or Split Paper. Authentication credentials remain those of the actual mailbox. Development email delivery must be restricted with MAIL_ALLOWLIST. MAIL_ENABLED=false pauses queued deliveries too.

Never put SMTP passwords into command arguments, Git, logs, or application files. Windows must inject the shared secret before starting the process, including after restarts. Provisioning prints only product/preparation status. Actual activation requires backup, migrations, validation and explicit preserved-data ownership mapping.

## Windows loader

The development deploy shell must run the external loader before starting PM2:

```powershell
. 'D:\app-runtime\tools\import_smtp_env.ps1' -Environment development
```

Start/update the backend with `--update-env` and keep `pm2 save` after successful health checks. The loader and SMTP secret remain outside Git. Do not log process environments or PM2 environment dumps. This configures SMTP transport only; identity configuration and migrations remain separate prerequisites.

Split now has a manual development deployment workflow. It runs only from dev after MySQL CI, requires an explicitly selected loopback port and checks the tested commit. Pending migrations require selecting apply_migrations; backup runs first. No legacy data import runs automatically. Configure the public reverse proxy separately after the loopback health check. The readiness runner alone does not start the API.
