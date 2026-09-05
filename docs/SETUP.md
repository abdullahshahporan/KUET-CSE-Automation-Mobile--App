# Mobile development and release

Use Flutter 3.44.1 / Dart 3.12.1, Java 17 and an installed Android SDK. From this repository:

```sh
dart tool/bootstrap.dart
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

Bootstrap copies missing `lib/config/*.dart.template` files and preserves existing configuration. Set the Supabase public project URL/key and the Dept Flow backend URL. For an Android emulator the template backend is `http://10.0.2.2:3000`; a physical device needs a reachable development host or an HTTPS deployment. The backend must run the matching authenticated-boundary migrations and be configured for database JWT signing. The ignored local config files and private signing keys must not be committed.

The app no longer authenticates directly against public password hashes. Password verification, change and recovery require the backend. Bearer tokens are kept in secure storage, and old preference tokens and saved biometric passwords are removed. Biometric login resumes a valid session; after its ten-hour expiry sign in again. Logout invalidates the backend session across devices.

All private REST access goes through the authenticated gateway. Notifications are filtered by PostgreSQL before retrieval and are created by the backend. FCM starts disabled in the template; enable it only with matching Firebase registration. Never place a dispatch secret or service account key in the app. Polling and configured FCM handle private updates; anonymous Realtime does not expose the private inbox.

Attendance requires administrator-managed active enrolments and configured room coordinates. Teachers submit manual attendance through an atomic endpoint. Students submit geo-attendance through the authenticated server; local presence monitoring provides advice and cannot mark them absent. Teachers can correct records. Teacher and CR room allocation requests require approval, and the published routine is owned by administration.

## Android release configuration

Debug builds retain `com.example.kuet_cse_automation`. No production identity has been chosen. Before a release, register a stable application ID and a matching Firebase Android app, then supply its `android/app/google-services.json` and private signing configuration. Create ignored `android/key.properties` containing `storeFile`, `storePassword`, `keyAlias` and `keyPassword` for your own release keystore.

Pass the Gradle project property `productionApplicationId` with the registered ID. For example, in PowerShell set `$env:ORG_GRADLE_PROJECT_productionApplicationId` to your real ID before `flutter build appbundle --release`. The build rejects missing/example IDs and missing private signing properties. Do not substitute a guessed ID or debug signing key. Verify signing, login/logout/recovery, attendance permissions, denied location, background FCM and notification audience on real devices before release.

The companion web repository's `docs/SETUP.md` describes database installation and staged upgrades. Deploy the matching server, policies and mobile client together. Existing deployment data, production signing, store publication, archive DOI and manuscript editing are outside this local verification run.
