# DayFlow — App Store submission checklist

## Done in the code base

| Requirement | Where |
|---|---|
| Sign in with Apple (Guideline 4.8, because Google sign-in exists) | `FE/lib/services/apple_auth_service.dart`, `BE/app/services/apple/*`, entitlement in `FE/ios/Runner/Runner.entitlements` |
| Account deletion in-app + Apple/Google token revocation (5.1.1(v)) | Settings → Delete account → `DELETE /api/v1/account` |
| Privacy policy reachable in the app (5.1.1(i)) | Login screen notice + Settings → Privacy Policy (`/privacy.html`) |
| Support URL | `/support.html` |
| Real app icon (all sizes, no alpha) | `FE/ios/Runner/Assets.xcassets/AppIcon.appiconset`, Android mipmaps |
| Privacy manifest bundled + data types declared | `FE/ios/Runner/PrivacyInfo.xcprivacy` (now in Copy Bundle Resources) |
| Purpose strings in English, explain on-device processing | `Info.plist` (camera, photos, motion) |
| No unused background modes (2.5.4) | `UIBackgroundModes` removed |
| Time Sensitive notifications entitlement | `Runner.entitlements` |
| Alarm ringtones in notifications | `FE/ios/Runner/Sounds/*.wav` |
| iPhone only, portrait | target `TARGETED_DEVICE_FAMILY = 1` |
| Review demo account with data | `REVIEW_PASSWORD=... bin/rails db:seed` |
| Release builds refuse a non-HTTPS / missing API URL | `ApiClient.baseUrl` |

## Manual steps

1. **Deploy the backend** over HTTPS with PostgreSQL (see `BE/README.md`), run
   `db:seed` with `REVIEW_EMAIL` / `REVIEW_PASSWORD`. Check
   `https://YOUR_API/privacy.html` and `/support.html` load.
2. **Apple Developer portal**
   - App ID `com.dayflow.app` with capabilities *Sign in with Apple* and
     *Time Sensitive Notifications*.
   - Keys → create a *Sign in with Apple* key → set `APPLE_TEAM_ID`,
     `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` on the server (needed to revoke
     tokens on account deletion).
3. **Google Cloud Console**
   - OAuth consent screen (publish it; the `calendar.readonly` scope is
     *sensitive* and needs Google verification before public launch). Use
     the privacy URL above.
   - Create clients: *Web* (→ `GOOGLE_WEB_CLIENT_ID/SECRET` on the server and
     `--dart-define=GOOGLE_SERVER_CLIENT_ID`), *iOS* (→
     `FE/ios/Flutter/GoogleSignIn.xcconfig` and
     `--dart-define=GOOGLE_IOS_CLIENT_ID`), *Android* (package + SHA-1).
   - Enable the Google Calendar API.
4. **Xcode** (`open FE/ios/Runner.xcworkspace`): select your Team under
   Signing & Capabilities; confirm both capabilities show up.
5. **Build**
   ```bash
   cd FE
   flutter build ipa --release \
     --dart-define=API_BASE_URL=https://YOUR_API \
     --dart-define=GOOGLE_SERVER_CLIENT_ID=XXX.apps.googleusercontent.com \
     --dart-define=GOOGLE_IOS_CLIENT_ID=YYY.apps.googleusercontent.com
   ```
   Upload `build/ios/ipa/*.ipa` with Transporter or Xcode Organizer.
6. **App Store Connect**
   - Privacy URL: `https://YOUR_API/privacy.html`; Support URL: `/support.html`.
   - App Privacy: Contact info (name, email), Identifiers (user ID),
     User content (photos, other content) — all *linked to user*, *not
     used for tracking*, purpose *App functionality*.
   - Review notes: give the review account; explain that alarms ring in-app
     in the foreground and as notifications (with the chosen ringtone) in
     the background; missions can be tried from the alarm editor
     (“Preview”); the QR mission falls back to math after 45 s.
   - Screenshots for 6.9" and 6.5" iPhones.
   - Age rating: 4+.

## Known limitations to mention if asked

- iOS does not let third-party apps play a looping alarm while in the
  background; DayFlow uses time-sensitive notifications with its ringtone
  (≤ 30 s) and rings fully once the app is opened.
