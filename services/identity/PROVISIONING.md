# Development identity provisioning

`python -m services.identity.provision` prepares external configuration only. It does not migrate a database, start a service, send email, or modify the SMTP source file.

Run from the repository root, with `services/identity/requirements.txt` installed. Supply `--product`, `--config-root`, `--secrets-root`, `--smtp-file`, `--public-url`, one or more `--google-id`, one or more `--apple-id`, `--sender`, and `--recipient`.

The config directory must already contain the product's `.database.env` for its expected `dev_<product>_db`. Both destination directories must exist with restrictive ACLs granting access only to the runtime/deployment account and administrators. Windows file creation inherits these ACLs; POSIX files use mode 0600.

The SMTP source is an existing external dotenv file with SMTP_HOST, SMTP_USER, SMTP_PASSWORD, and optional SMTP_PORT plus SMTP_SECURITY (ssl/starttls) or SMTP_SECURE. Invalid-certificate configurations are refused. The source file is never changed. Client IDs must be the actual registered Google/Apple applications; do not use placeholders to activate services.

The command exclusively creates independent signing/encryption keys and `<product>.identity.env`, with the supplied test recipient as the development mail allowlist. Existing files are refused, never overwritten. Validation does not connect to MySQL or SMTP. Service activation remains a separate deployment after backup, migrations, validation, and verified domain ownership mapping.

Do not put credentials into shell arguments or Git. The command accepts only the path to the existing SMTP source. It prints product/preparation status only.
