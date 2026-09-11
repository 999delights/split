# Controlled DEV recovery import

The recovered local cache contains 4 groups, 8 members, 29 expenses, 58 shares,
0 settlements and 4 metadata records. This is not a full Firebase export.
Original files remain untouched and outside Git.

Transfer the recovered `imported.db` from the Mac to a private Windows file
outside the runtime checkout. SHA-256:
`49cff069aeaa7ae2850a47f6da8678c0289a78f56d82a04e80c6a4705a9e4ac4`.

Use the existing Split Python venv. Run from a clean dev checkout containing
scripts/link_legacy_mysql.py. No backend restart or schema migration is needed.

1. Run the existing Windows DEV database backup tool and confirm success.
2. Run the import command below without --apply (dry run).
3. Check counts above, then repeat with --apply.
4. Confirm imported/exact_rows_verified, refresh mobile, compare group balances.

```powershell
& 'D:\app-runtime\venvs\development\split\Scripts\python.exe' `
  scripts/link_legacy_mysql.py `
  --source '<private Windows path to imported.db>' `
  --sha256 49cff069aeaa7ae2850a47f6da8678c0289a78f56d82a04e80c6a4705a9e4ac4 `
  --email '999delights@gmail.com' `
  --database-file 'D:\app-runtime\config\development\split.database.env'
```

The target must have exactly one active account with a Google identity and a
verified email matching the explicitly authorized target. No other account is
created or linked by name. Only dev_split_db is allowed. All data writes and
ownership links share one transaction. Existing group ID collisions abort.
The source-hash ledger makes repeat execution idempotent. Source timestamps,
minor-unit amounts, relationships, colors and icon metadata are preserved.
The profile nickname and all existing destination groups remain untouched.

## Explicit account/member binding repair

Migration 003 adds a nullable member_id relation to group membership. New groups
bind the creator to the self member during group creation. Existing recovered
groups are repaired separately using legacy_member_map and the source user ID,
scoped to the user_id recorded in split_imports. No names or row ordering are used.
Run the DEV deployment workflow manually with apply_migrations=true and
bind_recovered_members=true; backup precedes both migration and binding repair.
Expenses, amounts, shares and original recovery files are not changed.
API exposes my_member_id and keeps that member first for older mobile clients.
