# DayFlow — Privacy Policy

_Last updated: 29 October 2026_

DayFlow ("we", "the app") is an alarm and daily planner app. This policy explains
what data we collect, why, and the choices you have. The same policy is served
by the backend at `/privacy.html`.

## 1. Data we collect

| Data | Purpose | Stored |
|------|---------|--------|
| Name, email address | Account and sign-in | Our server |
| Password | Sign-in — stored only as a bcrypt hash | Our server |
| Google account id (Sign in with Google) | Sign-in | Our server |
| Apple account id, email or private relay email (Sign in with Apple) | Sign-in | Our server |
| Google Calendar events (read-only, only if you connect it) | Show your schedule in the app | Our server; the OAuth token is encrypted |
| Alarms, tasks, personal events | Core features | Our server |
| Wake-up history (dismiss time, snoozes, mission duration) | Wake-up report | Our server |
| Avatar photo (optional) | Profile | Our server |
| Registered QR / barcode value (QR mission) | Verify the mission | Our server |
| Theme, language, auth token | Preferences, keep you signed in | Your device only |

Camera images (QR mission) and motion-sensor readings (shake / walk missions)
are processed on the device in real time and are **never stored or uploaded**.

We do **not** collect location, contacts or advertising identifiers, do not
track you across apps or websites, and do not use advertising or analytics SDKs.
We do not sell or share your data.

## 2. Google user data

If you connect Google Calendar we request the read-only scope
`https://www.googleapis.com/auth/calendar.readonly`. Events are only used to
display your schedule inside DayFlow. DayFlow's use of information received
from Google APIs adheres to the
[Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy),
including the Limited Use requirements. You can disconnect at any time in
**Settings → Google Calendar**; imported events are deleted and the token is revoked.

## 3. Retention and deletion

Data is kept while your account exists. **Settings → Delete account**
permanently deletes your account and all associated data immediately and
revokes Google / Apple tokens.

## 4. Security

All traffic uses HTTPS. Passwords are hashed with bcrypt and OAuth tokens are
encrypted at rest.

## 5. Children

DayFlow is not directed to children under 13.

## 6. Contact

support@dayflow.app
