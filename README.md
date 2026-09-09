# Split

Legacy SwiftUI iOS client for shared groups, expenses and settlements.

## Current components

| Component | Location | State |
| --- | --- | --- |
| iOS client | `split/` and the Xcode project | Legacy, Firebase-backed |
| Product architecture | `docs/ARCHITECTURE.md` | Migration plan |
| Split API | not created yet | Planned on Windows for development/staging |
| Split database | Firebase today | Planned MySQL per environment |

The current app must remain buildable while Firebase data is inventoried and
exported. Do not remove Firebase, Pods or `GoogleService-Info.plist` until the
project is opened and verified on the Mac.

The target product identifier and universal-link namespace will use DDDCreate,
but those changes happen together with signing and the new backend integration.

