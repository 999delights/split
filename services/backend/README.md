# Split local v0 API

Python 3 standard library only. The API is intentionally bound to **127.0.0.1**.
This is a single-person development sandbox, not a public multi-user service.
Firebase and the legacy SwiftUI application remain untouched.

Set `SPLIT_DB_PATH` to a disposable database outside the repository and
`SPLIT_DEV_TOKEN` to a random secret of at least 24 characters, then run:

```sh
python3 services/backend/server.py
```

Port defaults to 3400; override with `PORT`. All `/api/v1` routes require
`Authorization: Bearer <SPLIT_DEV_TOKEN>`. GET `/health` is public.

- GET `/api/v1/state`: profile, groups, participants, expenses, shares, balances and settlements.
- POST `/api/v1/profile`: nickname.
- POST `/api/v1/groups`: name, icon (1–20), currency (RON/EUR/USD/GBP).
- POST `/api/v1/groups/:id/members`: name (offline participant).
- POST `/api/v1/groups/:id/settings`: name.
- POST `/api/v1/groups/:id/expenses[/:expenseId]`: name, amount in minor units, payer ID, shares keyed by member ID.
- POST `/api/v1/groups/:id/settlements`: sender, receiver and amount in minor units.

Amounts must balance exactly; participants must belong to the same group.
Settlements cannot exceed outstanding balances. Mutations are transactional.
Do not expose this local server through a tunnel. Production account scoping,
identity verification, rate limiting and MySQL deployment are future work.
