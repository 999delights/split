# Split Flutter v0

## Structure

| Component | Location | Status |
| --- | --- | --- |
| Original iOS / Firebase | `split/`, Xcode project | Preserved |
| Flutter iOS / Android | `apps/mobile` | Native local v0 |
| Split API | `services/backend` | Python / SQLite development sandbox |
| Business-rule tests | `tests` | Isolated temporary SQLite |

Original SwiftUI sources, illustrations and colors are the visual reference.
The Flutter implementation reuses the original illustration assets. It preserves
welcome branding, two-column group cards, group stats/activity, Spend, participant
cards, settings and green confirmation actions. The original running iOS home
screen was inspected on the existing simulator. This is **not yet a claim of
pixel-perfect parity across every screen**.

Implemented end-to-end against the API: create group, choose icon/currency, add
offline participants, create/edit expenses, equal or custom split, balances,
settlements, activity, rename group/profile, light/dark appearance and refresh.
Original email/Apple/Google authentication is not connected to the new API.
The welcome screen clearly offers a local preview rather than pretending to
authenticate. Invitations, profile-photo upload, push and destructive operations
remain pending. Existing Firestore data is not imported or modified.

## Run

Provide a private, untracked JSON file containing `SPLIT_API_BASE_URL` and
`SPLIT_DEV_TOKEN`, matching the server environment. Optional
`SPLIT_OPEN_PREVIEW: true` opens the local preview immediately for simulator QA.
Never ship that token or this local preview configuration in a public build.

```sh
cd apps/mobile
flutter run --dart-define-from-file=/absolute/private/config.json -d DEVICE_ID
```

For Android emulator the Mac loopback is normally reached using 10.0.2.2; configure
that development URL separately. Android has not yet been device-tested. The
backend binds to localhost only and is not a dev/staging/prod deployment.

## Validation

```sh
python3 -m unittest discover -s tests -v
cd apps/mobile
flutter analyze
flutter test
flutter build ios --simulator --dart-define-from-file=/absolute/private/config.json
```

## After all four v0 applications

1. Agree on shared account flows, provider support and session handling.
2. Inventory actual per-environment databases and backups, including STATZ.
3. Export a copy of Firebase data and reconcile expense balances before import.
4. Add account authorization, migrations, MySQL and isolated dev/staging/prod.
5. Complete visual comparison screen-by-screen and user acceptance before release.

No backend deployment is configured by this change. Dev code push must not be
mistaken for a running public Split API.
