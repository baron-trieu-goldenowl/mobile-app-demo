# DayFlow — Alarms & daily planner

DayFlow is an iOS/Android app that helps you **get up on time** and **plan
your day**. Inspired by Alarmy, an alarm only turns off after you complete a
mission. Once it's off, the app shows today's schedule and tasks, including
events from Google Calendar.

## Features

**Alarms**
- Repeat on chosen weekdays or ring once; quick alarm for naps (1–90 minutes).
- **7 wake-up missions**, each with 3 difficulty levels:

  | Mission | How to dismiss |
  |---|---|
  | Math | Solve arithmetic problems |
  | Memory | Repeat a sequence of lit tiles |
  | Typing | Type a phrase exactly |
  | Shake | Shake the phone |
  | Walk | Take a number of steps |
  | Puzzle | Solve a 3×3 sliding puzzle |
  | QR / barcode | Scan a registered code, e.g. the toothpaste in the bathroom |

- 5 ringtones; gradually increasing volume; vibration.
- Snooze with a maximum number of snoozes.
- **Wake-up check**: if you don't confirm you're awake within 3 minutes of dismissing, the alarm rings again.
- **Good morning** screen after dismissing: today's events and tasks.

**Schedule & tasks**
- **Google Calendar** sync (read-only) alongside personal events created in the app.
- Week / month calendar; a daily timeline combining events, alarms and tasks.
- Tasks with priority, due date and reminder notifications.

**Report**
- Wake-up streak, average wake-up time, snoozes, mission duration.
- Wake-up time chart for the last 7 days.

**Account**
- Sign in with email, **Google** or **Apple**.
- Vietnamese / English; dark / light theme.
- In-app account deletion.

## Tech stack

| Part | Technology |
|---|---|
| Mobile ([`FE/`](FE/README.md)) | Flutter 3.47 / Dart 3.13, `flutter_local_notifications`, `google_sign_in`, `sign_in_with_apple`, `mobile_scanner`, `audioplayers`, `sensors_plus` |
| Backend ([`BE/`](BE/README.md)) | Ruby 3.3, Rails 7.1 (API mode), PostgreSQL, Blueprinter, JWT, rswag (Swagger), RSpec, RuboCop |
| Integrations | Google OAuth 2.0 + Google Calendar API, Sign in with Apple |

## Repository layout

```
.
├── BE/                Rails API      → see BE/README.md
├── FE/                Flutter app    → see FE/README.md
├── SUBMISSION.md      App Store / Google Play submission checklist
└── PRIVACY_POLICY.md  Privacy policy
```

## Quick start

Requires Ruby 3.3, PostgreSQL, Flutter 3.47+, and Xcode (iOS) or Android Studio.

```bash
# 1. Backend — http://localhost:3000
cd BE
bundle install
cp .env.example .env          # works as-is for local development
bin/rails db:prepare db:seed
bin/rails server

# 2. App — in another terminal
cd FE
flutter pub get
cp env/example.json env/dev.json   # Android emulator: use http://10.0.2.2:3000
open -a Simulator
flutter run --dart-define-from-file=env/dev.json
```

Log in with `review@dayflow.app` / `Review1234`.
API docs: http://localhost:3000/api-docs

Detailed setup and troubleshooting: [BE/README.md](BE/README.md),
[FE/README.md](FE/README.md).

## Releasing

[SUBMISSION.md](SUBMISSION.md) lists the steps to ship to the App Store and
Google Play: deploying the backend, configuring Google/Apple, signing,
privacy details and the reviewer account.
