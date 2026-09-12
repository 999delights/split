# Product identity and Admin integration

Current DEV integration and exact Admin contract: [ACCOUNT-ADMIN-V1](../../docs/ACCOUNT-ADMIN-V1.md).

Google/Apple token verification, email verification/reset, rotating sessions, device
metadata and explicit same-account linking are implemented with the product MySQL
schema. The Admin contract provides sanitized account/session/mail views and a
versioned template editor used by the SMTP worker. All configuration secrets remain
external on Windows. Provider consent and real email delivery require their separate
end-to-end verification; code and migration tests are not proof of successful delivery.

Old provider sessions and product data are preserved. The four products have separate
accounts and databases; no silent cross-provider or cross-product email merge.

Run unit tests with `python -m unittest discover -s services/identity -t . -p 'test_*.py'`.
The database-checks workflow separately tests fresh/repeated migrations in disposable
MySQL before the existing Windows DEV deployment workflow can run.
