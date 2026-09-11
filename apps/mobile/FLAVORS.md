# Split DEV native Google login

DEV bundle/applicationId: `com.dddcreate.split.dev`.

Run from apps/mobile:

```sh
flutter test
flutter build ios --simulator --debug --flavor dev --dart-define-from-file=config/development.json
flutter build apk --debug --flavor dev --dart-define-from-file=config/development.json
```

Development.json contains only public DEV endpoint/client identifiers.
Flutter requests a native Google ID token using the Web client as serverClientId,
then POSTs it to /api/auth/google. Android credentials are matched by package and
signing SHA-1 in Google Cloud; the Android OAuth client ID is not passed to Flutter.
iOS DEV xcconfig supplies GIDClientID, GIDServerClientID and the reversed URL scheme.
Refresh credentials are stored in secure storage scoped to this product and API.
Access tokens remain in memory. Launch refreshes the session; logout revokes it.
No legacy groups are imported or assigned by this mobile change.

End-to-end checklist: Google login, restart, refresh, logout, relogin on both devices.
Real Google testing requires the authorized test user's interaction.
Router DNS returned NXDOMAIN during installation while public DNS resolved the backend.
Resolve DNS before interpreting transport failures as OAuth failures.
Only DEV flavor is added here; staging/production deployment and data are untouched.
