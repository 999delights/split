# Split architecture

## Ownership

Split is an independent product. This repository currently owns a SwiftUI iOS
client. It does not yet contain the future Split backend.

## Current state

The legacy client talks directly to Firebase Auth, Firestore, Storage and Dynamic
Links. Existing Firestore documents use three principal collections:

- `users`: email, nickname, profile image and group IDs;
- `groups`: members, created users, payment references and display metadata;
- `payments`: payer, amount, participants, split values and settlement flags.

The existing model stores amounts as strings and several relationships as maps or
arrays. Preserve this data for export, but do not copy that shape directly into the
new relational schema.

## Environments

| Environment | Backend runtime | Database | iOS build |
| --- | --- | --- | --- |
| Development | Windows | `dev_split_db` | Debug |
| Staging | Windows, isolated process/env | `staging_split_db` | TestFlight |
| Production | Hetzner | `split_db` | App Store |

## Target data model

Use normalized entities for users, groups, memberships, expenses, expense shares,
settlements, invitations, devices and entitlements. Store money as integer minor
units plus ISO currency, and store timestamps in UTC.

## Migration order

1. Inventory Firebase rules, indexes, document counts and Storage objects.
2. Export Firebase Auth identities, Firestore documents and required media.
3. Design versioned Split API contracts and MySQL migrations.
4. Build the Windows development backend and import a copy into `dev_split_db`.
5. Replace direct Firebase reads feature by feature behind a client repository layer.
6. Replace Dynamic Links with universal links owned under `dddcreate.com`.
7. Validate account, group, expense and settlement parity in staging.
8. Move production API/database to Hetzner and retire Firebase only after reconciliation.

Do not delete Firebase configuration or tracked project metadata during the audit.
Removal happens only after export, migration and release verification.

Xcode per-user state is not product source and must remain untracked. CocoaPods
and the Firebase configuration stay frozen until the first verified Mac build.

## Admin contract

The company admin receives account status, subscription/revenue summaries, app
version and service health. Expense contents and group activity remain private.
