# DayFlow — Backend API (Rails 7.1 + PostgreSQL)

REST API for the DayFlow app: accounts (email, Google, Apple), alarms, tasks,
calendar (with Google Calendar sync), wake-up history and notifications.
API docs (Swagger) are served at `/api-docs`.

## 1. Requirements

| Tool | Version |
|---|---|
| Ruby | 3.3.0 (see `.ruby-version`; install with rbenv / asdf) |
| Bundler | 2.5+ |
| PostgreSQL | 14+ (tested with 17) |

Install PostgreSQL on macOS:

```bash
brew install postgresql@17
brew services start postgresql@17
```

## 2. Run locally

```bash
cd BE
bundle install

# Environment variables (.env is gitignored)
cp .env.example .env
```

The example file works as-is when PostgreSQL is installed with Homebrew (it
connects as your macOS user). Only edit it if:

| Situation | Change |
|---|---|
| PostgreSQL has its own user / password (Docker, Postgres.app…) | Uncomment `DB_USERNAME`, `DB_PASSWORD` |
| You want a different demo account password | `REVIEW_PASSWORD` |
| You want to try Google / Apple sign-in | See section 5 |

> Leave variables without a value commented out (`# KEY=`). Never leave
> `KEY=` empty: Rails reads it as an empty string (an empty `DATABASE_URL=`
> breaks the DB connection). `SECRET_KEY_BASE` and `AR_ENCRYPTION_*` are only
> required in production.

Create the database and sample data, then start the server:

```bash
bin/rails db:prepare      # creates dayflow_development and runs migrations
bin/rails db:seed         # creates review@dayflow.app with sample data
bin/rails server          # http://localhost:3000
```

Check it works:

```bash
curl http://localhost:3000/up                        # 200
open http://localhost:3000/api-docs                  # Swagger UI
```

To try requests in Swagger: call `POST /api/v1/auth/login` with
`review@dayflow.app` and the password from `REVIEW_PASSWORD`, copy the
`token`, click **Authorize** and paste it.

## 3. Swagger / OpenAPI

- UI: `http://localhost:3000/api-docs`
- File: `swagger/v1/swagger.yaml`, generated from the specs in
  `spec/integration/` with [rswag](https://github.com/rswag/rswag). Every
  documented endpoint runs as a real test, so the docs always match the code.

After adding or changing an endpoint, update its spec in
`spec/integration/api/v1/` and regenerate the file:

```bash
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
```

Swagger UI is off in production by default. Turn it on with
`ENABLE_API_DOCS=true`.

## 4. Tests and lint

```bash
RAILS_ENV=test bin/rails db:prepare   # first time only
bundle exec rspec                     # request, model and integration (Swagger) specs
bundle exec rubocop                   # rubocop-rails, -performance, -rspec
bundle exec rubocop -A                # auto-fix style offenses
```

All outgoing requests (Google, Apple) are stubbed with WebMock, so the suite
runs without network access.

## 5. Google & Apple sign-in (optional locally)

| Variable | Where to get it |
|---|---|
| `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_WEB_CLIENT_SECRET` | Google Cloud Console → Credentials → OAuth client *Web application*. Enable the Google Calendar API |
| `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_ANDROID_CLIENT_ID` | iOS / Android clients (extra accepted token audiences) |
| `APPLE_BUNDLE_ID` | `com.dayflow.app` |
| `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | developer.apple.com → Keys → *Sign in with Apple* key (.p8; write newlines as `\n`). Used to revoke tokens on account deletion |

Without these, email sign-in works normally. Google endpoints return a
"not configured" error.

## 6. Project structure

```
app/
  blueprints/            JSON serializers (Blueprinter)
  controllers/
    concerns/            Authenticatable (JWT), ErrorRendering
    api/v1/              BaseController + resources
    api/v1/auth/         signup, login, google, apple
  models/                Models, validations, scopes
  services/
    application_service.rb  `Service.call(...)` base class
    external_http.rb     JSON HTTP client for Google / Apple
    auth/                IdentitySignIn, GoogleSignIn, AppleSignIn
    google/              OauthClient, CalendarConnection, CalendarSync
    apple/               IdentityToken (JWKS verification), TokenClient (revoke)
    accounts/            Destroy (revokes tokens, deletes data)
lib/json_web_token.rb    API access tokens (30 days)
spec/
  requests/, models/     Behavior specs
  integration/           rswag specs → swagger/v1/swagger.yaml
swagger/v1/swagger.yaml  OpenAPI 3 document
public/privacy.html      Privacy policy (App Store URL)
public/support.html      Support page
```

## 7. API overview

Prefix `/api/v1`. Auth header: `Authorization: Bearer <token>`.
Errors always look like `{ "error": "...", "details": { "field": ["..."] } }`.

| Method | Path | Description |
|---|---|---|
| POST | `/auth/signup`, `/auth/login` | Email + password |
| POST | `/auth/google` | `{ id_token, server_auth_code? }` |
| POST | `/auth/apple` | `{ identity_token, authorization_code?, name? }` |
| GET / PATCH | `/profile` | JSON, or multipart (`avatar`) |
| DELETE | `/account` | Permanent deletion; revokes Google/Apple tokens |
| CRUD | `/alarms`, `/tasks`, `/calendar_events` | Google events are read-only |
| POST | `/calendar_sync` | Import Google Calendar |
| POST / DELETE | `/google_connection` | Link / unlink Google Calendar |
| GET / POST | `/wake_logs?days=30` | Wake-up history |
| GET / PATCH | `/notifications`, `/notifications/:id/read`, `/notifications/read_all` | In-app notifications: Google Calendar sync results (`calendar_synced`, `calendar_sync_failed`) and wake-up streak milestones (`wake_streak`, at 3/7/14/30/60/100/365 days) |

Request/response details: see Swagger UI.

## 8. Production deployment

The Docker image (`Dockerfile`) runs `db:prepare` on boot.

```bash
docker build -t dayflow-api .
docker run -p 3000:3000 --env-file .env.production dayflow-api
```

Required variables: `DATABASE_URL`, `SECRET_KEY_BASE`, `AR_ENCRYPTION_*`,
`GOOGLE_WEB_CLIENT_ID`, `GOOGLE_WEB_CLIENT_SECRET`, `APPLE_TEAM_ID`,
`APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`, `REVIEW_PASSWORD`.
Store avatars on S3 or similar (`ACTIVE_STORAGE_SERVICE`), because container
disks are not persistent. HTTPS is required (`force_ssl` is on).
