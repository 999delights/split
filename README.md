# Split

Legacy SwiftUI iOS client for shared groups, expenses and settlements.

## Current components

| Component | Location | State |
| --- | --- | --- |
| iOS client | `apps/ios-legacy/` (`split/` sources, Xcode project and workspace, Pods, images) | Legacy, Firebase-backed |
| Product architecture | `docs/ARCHITECTURE.md` | Migration plan |
| Flutter mobile | `apps/mobile/` | Local native v0, iOS simulator |
| Split API | `services/backend/` | Local v0 Python / SQLite |
| Split database | Firebase today | Planned MySQL per environment |

The current app must remain buildable while Firebase data is inventoried and
exported. Do not remove Firebase, Pods or `GoogleService-Info.plist` until the
project is opened and verified on the Mac. The whole Xcode project moved together
into `apps/ios-legacy/`, so its relative paths are unchanged: open
`apps/ios-legacy/split.xcworkspace` and run `pod install` there.

The target product identifier and universal-link namespace will use DDDCreate,
but those changes happen together with signing and the new backend integration.


Flutter v0 setup, implemented flows and remaining parity work: [docs/FLUTTER-V0.md](docs/FLUTTER-V0.md).
