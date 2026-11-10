# Phase 7D Flutter Verification Checklist

## Source inspection

- [x] SDK constraint: `campusfix-mobile/pubspec.yaml` declares Dart `^3.13.2`.
- [x] API URL: `lib/core/config/app_config.dart` defaults to `http://10.0.2.2:8000/api` (Android emulator host loopback); override with `--dart-define=API_BASE_URL=...`.
- [x] API client: shared Dio client with bearer-token interceptor, timeouts, and 401 session-expiry callback.
- [x] Session: `AuthRepository` uses existing secure storage; logout calls backend then clears local session; expired sessions clear/redirect through the shared auth notifier.
- [x] Role routing: GoRouter directs STUDENT, STAFF, and ADMIN to separate role destinations and blocks cross-role paths. Mobile ADMIN view is a landing screen pointing users to the web dashboard, not a full admin toolset.
- [x] Student flow: complaint list/details/submission, catalogs, image upload/retrieval, feedback history/submission, notifications/read state.
- [x] Staff flow: current assignments, assignment-scoped details, status updates, protected image retrieval, notifications/read state.
- [x] Tests exist for auth repository/notifier, widget auth flows, Phase 5 models/repositories, role guards, 401 expiration, notifications, and staff status payloads.
- [ ] SDK-dependent verification: not run here because Dart/Flutter are missing.

## Target Windows commands

From `campusfix-mobile` after installing Flutter with Dart satisfying `^3.13.2` and configuring Android Studio/Android SDK:

```powershell
flutter doctor -v
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Expected: `flutter doctor -v` reports the Android toolchain/device setup; package resolution completes; formatter/analyzer report no issues; tests exit successfully; debug APK is emitted under `build/app/outputs/flutter-apk/`.

## API and device requirements

- Start the Core PHP API with a compatible disposable local database before testing network workflows. A working local HTTP endpoint without a compatible schema is insufficient for login or CRUD flows.
- Android emulator default API URL is `10.0.2.2:8000`; physical devices need the developer machine’s reachable LAN address and a firewall/API bind configuration that permits local testing.
- Do not pass passwords or JWTs in `--dart-define`; the define is for the API URL only.
- For complaint images, backend upload constraints are at most 5 JPEG/PNG/WebP files, each no more than 5 MiB. Test PHP `upload_max_filesize`/`post_max_size`, backend upload-directory write access, and owner/current-assignee authorization for retrieval.

## Manual role checklist

- [ ] STUDENT login and role landing; submit complaint with/without valid images; view only own complaint details/images; submit feedback only when backend allows; mark own notification read; logout and reject revoked JWT.
- [ ] STAFF login and role landing; see only current assignments; open assigned detail/image; update allowed status; mark own notification read; logout.
- [ ] ADMIN login reaches the web-only mobile landing screen; student/staff paths redirect to admin landing; logout.
- [ ] Expire/revoke a test session and verify the mobile app clears the secure session and returns to unauthenticated navigation.

Do not claim these manual flows pass until run on a local device/emulator with dedicated test accounts.
