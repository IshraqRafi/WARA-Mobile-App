# Production setup

Wara signs users in with Google only. Every user gets a `users/{uid}` profile;
managers create an agency, and editors join one with its join key.

## 1. Firebase project config

Generate `lib/firebase_options.dart` (gitignored) with FlutterFire:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

`lib/firebase_options.dart.example` shows the expected shape. Also place
`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`
from the Firebase console.

## 2. Enable the Google provider

Firebase console -> Authentication -> Sign-in method -> Google -> Enable, and
set a support email. Disable Email/Password if it was enabled earlier; the
app no longer uses it.

## 3. Android SHA fingerprints

Google sign-in on Android fails (error 10 / DEVELOPER_ERROR) unless the
signing certificate is registered. Add both SHA-1 and SHA-256 under
Project settings -> Your apps -> Android app -> Add fingerprint, for:

- the debug keystore: `cd android && ./gradlew signingReport`
- your release/upload keystore:
  `keytool -list -v -keystore <release.jks> -alias <alias>`
- the Google Play app signing key (Play Console -> Setup -> App signing),
  if you distribute through Play.

Download `google-services.json` again after adding fingerprints.

## 4. iOS

Add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as a URL scheme
in `ios/Runner/Info.plist` (CFBundleURLTypes).

## 5. Build-time dart-defines

| Define                    | Purpose                                                  |
|---------------------------|----------------------------------------------------------|
| `GOOGLE_SERVER_CLIENT_ID` | Web OAuth client ID (Google Cloud -> Credentials, "Web client (auto created by Google Service)"). Needed on Android to get an ID token. |

```
flutter run   --dart-define=GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
flutter build appbundle --release --dart-define=GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
```

## 6. Deploy the Firestore rules

```
firebase deploy --only firestore:rules
```

The rules require sign-in, scope projects, conversations and notifications to
the caller's `users/{uid}.agencyId`, and restrict DMs to their
`participantIds`. Deploy them before releasing; the app's queries are written
to match them.

## 7. Crashlytics

Already wired: `firebase_crashlytics` in pubspec, the
`com.google.firebase.crashlytics` Gradle plugin in `android/settings.gradle.kts`
and `android/app/build.gradle.kts`, and `_initCrashlytics()` in `lib/main.dart`
(`FlutterError.onError` + `PlatformDispatcher.onError`). Collection is on only
in release builds (`kReleaseMode`); debug/profile send nothing.

1. Firebase console → Build → Crashlytics → Enable for the Android app.
2. Build and run a release build (`flutter run --release`), open the app,
   then restart it; the first report shows up within a few minutes.
3. iOS: add the Crashlytics run script / dSYM upload in Xcode
   (`flutterfire configure` can do this) before shipping on iOS.

## First run

- **Manager:** Continue with Google -> "Name your agency" -> agency is created
  with a join key (Settings shows and copies it).
- **Editor:** Continue with Google -> "Join as editor" -> enter the join key
  and full name -> lands on the editor home.

## Notifications

In-app only (Spark plan, no Cloud Functions). The sender's client writes to
`users/{recipientUid}/notifications/{id}` with
`{type: revision|approved|message|assigned|submitted, projectId?, chatId?, title, body, fromUid, createdAt (server time), read: false}`.
Managers notify their editors (revision, approved, assigned, message); editors
notify their own manager (submitted, message). Only the recipient can read,
mark read, or delete. The old agency-wide `agencies/{id}/notifications`
collection is locked by the rules; existing docs were not deleted.

Future work: push notifications via FCM (needs device tokens and a trusted
sender, i.e. Cloud Functions on the Blaze plan).
