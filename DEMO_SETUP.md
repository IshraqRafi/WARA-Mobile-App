# Demo account setup

The app no longer contains hardcoded demo logins. The demo manager and editor
must exist as real Firebase Auth users so that the locked-down Firestore rules
(`firestore.rules`) allow their reads and writes.

## 1. Create the Auth users (Firebase console)

Firebase console -> project `wara-91aa3` -> Authentication -> Users -> Add user.

| Role    | Suggested email               | Password                 |
|---------|-------------------------------|--------------------------|
| Manager | a demo address on a domain you own | strong, kept outside the repo |
| Editor  | a demo address on a domain you own | strong, kept outside the repo |

Make sure the Email/Password sign-in provider is enabled (Authentication ->
Sign-in method). Never commit these passwords.

## 2. Create their profile docs (Firestore -> `users/{uid}`)

Copy each user's UID from the Auth tab and create `users/{uid}`:

Manager:
```
role: "manager"
name: "Ishraq Rafi"
email: <manager email>
agencyId: "agency_demo_wara"
agencyName: "Wara Media Group"
agencyJoinKey: "WARA-7742"
isProfileComplete: true
```

Editor:
```
role: "editor"
name: "<editor name>"
email: <editor email>
agencyId: "agency_demo_wara"
agencyName: "Wara Media Group"
agencyJoinKey: "WARA-7742"
isProfileComplete: true
```

Without `agencyId`, the manager login would auto-create a brand-new empty
agency, and the rules would block access to the demo agency's data.

## 3. Create the agency doc (`agencies/agency_demo_wara`), if missing

```
name: "Wara Media Group"
managerUid: <manager UID>
managerName: "Ishraq Rafi"
joinKey: "WARA-7742"
```

## 4. Deploy the rules

```
firebase deploy --only firestore:rules
```

Do steps 1-3 BEFORE deploying the rules, then log in with both accounts on the
device and check projects, chat and notifications load.

Existing devices that saved an old local demo session: log out and back in
once so a real Firebase session exists.

## Build-time config (--dart-define)

The Google sign-in server client ID and the owner email are no longer in the
source. Pass them at build/run time:

| Define                    | What it is                                                     | If omitted |
|---------------------------|----------------------------------------------------------------|------------|
| `GOOGLE_SERVER_CLIENT_ID` | OAuth **Web** client ID (Firebase console -> Authentication -> Sign-in method -> Google -> Web SDK configuration, or Google Cloud -> Credentials) | Android falls back to `default_web_client_id` from `google-services.json` |
| `OWNER_EMAIL`             | Agency owner's email; that account gets the owner display name | No special-casing; manager shows "Agency Director" unless a profile name exists |
| `OWNER_NAME` (optional)   | Display name for the owner                                      | `Ishraq Rafi` |

Easiest: create `config/dart_defines.json` (already ignored by git, see below):

```json
{
  "GOOGLE_SERVER_CLIENT_ID": "<web-client-id>.apps.googleusercontent.com",
  "OWNER_EMAIL": "<owner email>"
}
```

Run / build:

```
flutter run --dart-define-from-file=config/dart_defines.json
flutter build apk --release --dart-define-from-file=config/dart_defines.json
```

Or inline:

```
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com --dart-define=OWNER_EMAIL=<owner email>
```

Never commit `config/dart_defines.json`.
