# DayFlow API (Rails 7.1, PostgreSQL)

## Structure

```
app/
  blueprints/            JSON serializers (Blueprinter)
  controllers/
    concerns/            Authenticatable (JWT), ErrorRendering
    api/v1/              Versioned API; BaseController + resources
    api/v1/auth/         signup, login, google, apple
  models/                ActiveRecord models (validations, scopes)
  services/
    application_service.rb  `Service.call(...)` base
    external_http.rb     JSON-over-HTTPS client for Google / Apple
    auth/                IdentitySignIn, GoogleSignIn, AppleSignIn
    google/              OauthClient, CalendarConnection, CalendarSync
    apple/               IdentityToken (JWKS verify), TokenClient (revoke)
    accounts/            Destroy (revokes tokens, deletes data)
lib/json_web_token.rb    API access tokens (30 days)
spec/                    RSpec request + model specs (WebMock, FactoryBot)
public/privacy.html      Privacy policy (App Store / Play URL)
public/support.html      Support page
```

## Setup

```bash
cp .env.example .env          # fill in values
bundle install
bin/rails db:prepare db:seed   # creates the App Review account
bin/rails server
```

## Quality

```bash
bundle exec rspec
bundle exec rubocop            # rubocop-rails, -performance, -rspec
```

## API (prefix `/api/v1`, `Authorization: Bearer <token>`)

| Method | Path | |
|---|---|---|
| POST | `/auth/signup`, `/auth/login` | email + password |
| POST | `/auth/google` | `{ id_token, server_auth_code? }` |
| POST | `/auth/apple` | `{ identity_token, authorization_code?, name? }` |
| GET/PATCH | `/profile` | JSON or multipart (`avatar`) |
| DELETE | `/account` | deletes everything, revokes Google/Apple tokens |
| CRUD | `/alarms`, `/tasks`, `/calendar_events` | Google events are read-only |
| POST | `/calendar_sync` | import Google Calendar |
| POST/DELETE | `/google_connection` | link / unlink Google Calendar |
| GET/POST | `/wake_logs?days=30` | wake-up history |
| GET, PATCH | `/notifications`, `/notifications/:id/read`, `/notifications/read_all` | |

Errors: `{ "error": "message", "details": { "field": ["..."] } }`.

## Production

Docker image (`Dockerfile`) runs `db:prepare` on boot. Required env:
`DATABASE_URL`, `SECRET_KEY_BASE`, `AR_ENCRYPTION_*`, `GOOGLE_WEB_CLIENT_ID`,
`GOOGLE_WEB_CLIENT_SECRET`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`,
`REVIEW_PASSWORD`. Use `ACTIVE_STORAGE_SERVICE` with S3 (or similar) for avatars —
container disks are ephemeral.
