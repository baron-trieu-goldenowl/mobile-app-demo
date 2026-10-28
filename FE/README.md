# DayFlow — Mobile app (Flutter)

The DayFlow iOS/Android app: mission alarms, a schedule synced with Google
Calendar, tasks and a wake-up report. It talks to the Rails backend in
[`../BE`](../BE/README.md).

## 1. Requirements

| Tool | Version |
|---|---|
| Flutter | 3.47+ (Dart 3.13+) — check with `flutter --version` |
| Xcode + CocoaPods | Xcode 16+, `pod --version` 1.16+ (for iOS) |
| Android Studio | Android SDK 35 and an emulator (for Android) |
| Backend | `../BE` running — see [BE/README.md](../BE/README.md) |

Check your setup with `flutter doctor`.

## 2. Run the app locally

```bash
cd FE
flutter pub get

# Build-time config (this file is gitignored)
cp env/example.json env/dev.json
```

Edit `env/dev.json` to point at your backend:

| Device | `API_BASE_URL` |
|---|---|
| iOS Simulator | `http://localhost:3000` |
| Android Emulator | `http://10.0.2.2:3000` (the Mac's localhost as seen from the emulator) |
| Physical phone (same Wi-Fi) | `http://<your computer's LAN IP>:3000` |

Start a simulator / emulator, then run:

```bash
open -a Simulator                 # iOS
flutter devices                   # list devices
flutter run --dart-define-from-file=env/dev.json
# or pick a device: flutter run -d <device-id> --dart-define-from-file=env/dev.json
```

While running: `r` hot reload, `R` hot restart, `q` quit.

Debug Android builds allow plain HTTP so they can reach the local backend.
Release builds require HTTPS.

### Test account

After running `bin/rails db:seed` in BE:

| Email | Password |
|---|---|
| `review@dayflow.app` | `Review1234` |

Or tap **Don't have an account? Sign up** (password: 8+ characters with
upper case, lower case and a digit).

### Google / Apple sign-in (optional)

- **Google**: create OAuth clients in Google Cloud Console and fill in
  `env/dev.json`:
  - `GOOGLE_SERVER_CLIENT_ID`: the *Web application* client (the backend
    uses the same client).
  - `GOOGLE_IOS_CLIENT_ID`: the *iOS* client (bundle ID `com.dayflow.app`).
    A scheme pre-action (`ios/scripts/dart_defines.sh`) copies it into
    Info.plist (`GIDClientID` and the reversed-client-ID URL scheme), so the
    env file is the only place to set it. Stop and re-run `flutter run`
    after changing it.
  - Android: create an *Android* client for package `com.dayflow.app` with
    the SHA-1 of your debug keystore (`cd android && ./gradlew signingReport`).
- **Apple**: iOS only. Open `ios/Runner.xcworkspace` in Xcode and pick your
  Team under *Signing & Capabilities*. On the simulator, sign in to an Apple
  ID in the simulator's Settings app.

Without this setup the two buttons show a "not configured" error. Email
sign-in still works.

## 3. Code quality

```bash
flutter analyze        # strict lints (see analysis_options.yaml)
dart format lib test   # format code
flutter test           # unit + widget tests
```

## 4. Release builds

```bash
# iOS (.ipa for App Store Connect)
flutter build ipa --release --dart-define-from-file=env/prod.json

# Android (.aab for Google Play) — needs android/key.properties
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

`env/prod.json` has the same shape as `env/example.json`, but `API_BASE_URL`
must be **HTTPS**. Release builds refuse to start without `API_BASE_URL`.
Store submission steps: [../SUBMISSION.md](../SUBMISSION.md).

## 5. Project structure

```
lib/
  main.dart              App setup, routes, opens the alarm when a notification is tapped
  l10n/app_strings.dart  Vietnamese / English strings
  theme/app_theme.dart   Colors, light/dark theme
  models/                Alarm, Mission, CalendarEvent, Task, WakeLog, User
  services/
    api_client.dart        HTTP client (/api/v1 prefix, Bearer token)
    auth_service.dart      Email, Google and Apple sign-in; token storage
    alarm_scheduler.dart   Watches the clock; snooze, quick alarm, wake-up check
    notification_service.dart  Schedules alarm and task reminder notifications
    sound_service.dart     Plays ringtones with gradual volume
    ...                    Calendar, Task, WakeLog, Profile, Settings
  screens/               Screens (alarms, ringing, missions, schedule,
                         tasks, report, settings, login…)
  widgets/               AppShell (tab bar) and shared components
assets/sounds/           5 ringtones (also copied to ios/Runner/Sounds and
                         android/app/src/main/res/raw for notifications)
env/                     Per-environment build config (*.json is gitignored)
```

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| `Network error` / can't log in | Backend not running or wrong `API_BASE_URL`. Try `curl <API_BASE_URL>/up` |
| Android can't reach the API | Use `http://10.0.2.2:<port>`, not `localhost` |
| CocoaPods errors on iOS | `cd ios && pod install --repo-update`, then run again |
| Alarm doesn't ring | Allow notifications (Settings → Alarm permissions). In the background iOS can only play the notification sound |
