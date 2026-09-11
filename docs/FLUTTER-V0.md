# Split Flutter DEV — Swift parity audit

The original `split/Views/` sources and the installed Swift app are the reference.
The Flutter client uses the authenticated Windows MySQL backend in DEV. It does
not open Firebase or the recovered SQLite export. See `WINDOWS-DEV.md` and
`WINDOWS-DEV-DEPLOY.md` for identity and deployment configuration.

## Screen and behavior coverage

| Original source | Flutter behavior |
| --- | --- |
| `home/HomeView.swift`, `lists/listGroupView.swift` | Original illustration assets, two-column group cards, counts, group date order and personal total. Mixed currencies remain separate. |
| `groups/GroupView.swift`, `StatsView.swift` | Personal `You owe` / `You're owed` and `Spent`, original red/green palette, Spend button, stats/activity underline and swipe. The signed-in participant is excluded from their own Stats cards. |
| `groups/CreatedUserView.swift`, `CreatedUserStatsView.swift` | Tap a participant for their own stats and spending on their behalf. Relative debts identify who owes whom. Settlement requires explicit confirmation. |
| `groups/ActivityView2.swift` | Own or involved payments only, newest first; payer avatar, title left/total right, green `You get back`, red `Spent` / `You owe`, blue border for one's own payments. Tap opens a payment sheet. Repayments remain visible. |
| `spend/getPaymentInfo.swift`, `PaymentList.swift` | Name → amount → two-column split selection → review; 65px avatars, blue checkmarks and selection highlights, purple editable amounts, all-participants toggle and manual remainder allocation. |
| `spend/PaymentView.swift` | Date/time, group, Edit, name/amount, `by me`, participant count and pill rows. Editing starts at the saved split and retains unequal shares until the user changes them. Tap an amount selects its text. |
| `groups/create.swift`, `GroupSettings.swift` | Twenty original group icons, group name, local participant creation, group name/icon changes, original date/counts and owner-only delete confirmation. |
| `settings/SettingsView.swift`, `changeNickname.swift` | Nickname editor, original section hierarchy, light/dark/system themes and logout confirmation. |

Amounts remain integer minor units. The original debt-chain cancellation is
reproduced, but small debts are never silently hidden and the split must total
exactly the expense. The old Swift tolerances are deliberately not copied.
Member identity uses `my_member_id`, not participant position or name.

## Outstanding parity, explicitly not claimed complete

- Original invitations depended on Firebase Dynamic Links. The new authenticated
  invite/join backend and replacement links are not implemented. The button
  reports this honestly; creating a local participant works.
- Original profile/group photo picking and Firebase Storage upload still need a
  replacement media flow. The twenty bundled group icons work.
- Push, email-notification preferences and Report a problem were empty actions in
  the inspected Swift settings source. They are not represented as working in DEV.
- The post-create `Group Created` / share screen is not yet ported; Flutter returns
  to the refreshed group list after successful creation.
- Visual comparison is a screen-by-screen effort, not a blanket claim of 100%
  pixel parity on every device, accessibility size or unvisited state.

## Data and backend changes in the parity pass

`POST /api/v1/groups/<id>/settings` now accepts a validated icon (1–20).
`POST /api/v1/groups/<id>/delete` is owner-only and deletes that group's related
rows transactionally, only after an explicit user action. State includes the role
so non-owners are not offered this control. No migrations, imports or database
cleanup are performed by this UI change. Existing auth remains unchanged.

The recovered source copy remains outside Git under the workspace's private
`.local/split-import` folder. Its SHA-256 is checked unchanged during validation.
Live UI comparisons are read-only: no real expenses, shares or settlements are
created/changed to produce screenshots. Domain write tests use disposable data.

## Run and validate

From the repository root:

```sh
python -m unittest services.identity.test_identity services.identity.test_http services.identity.test_provider services.identity.test_provision services.identity.test_deployment_check services.backend.test_mysql_app -q
cd apps/mobile
flutter test
flutter analyze --no-pub
flutter build ios --simulator --debug --flavor dev --no-pub --dart-define-from-file=config/development.json
flutter build ios --release --flavor dev --no-pub --dart-define-from-file=config/development.json
flutter build apk --debug --flavor dev --no-pub --dart-define-from-file=config/development.json
```

`config/development.json` contains public client configuration only. Never embed
private auth tokens, certificates or provider secrets. Backend changes pushed to
`dev` trigger the existing Windows checks/backup/deploy workflow; Mac does not
manage Windows PM2 directly.
