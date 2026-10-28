require "rails_helper"

# OpenAPI document generated from the specs in spec/integration:
#   bundle exec rake rswag:specs:swaggerize  ->  swagger/v1/swagger.yaml
RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s
  config.openapi_format = :yaml

  timestamp = { type: :string, format: "date-time" }
  nullable_timestamp = { type: :string, format: "date-time", nullable: true }

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "DayFlow API",
        version: "v1",
        description: "Backend for the DayFlow alarm & daily planner app. " \
                     "Authenticate with POST /api/v1/auth/login (or Google / Apple), " \
                     "then send `Authorization: Bearer <token>`."
      },
      servers: [{ url: "{baseUrl}", variables: { baseUrl: { default: "http://localhost:3000" } } }],
      tags: [
        { name: "Auth" }, { name: "Profile" }, { name: "Alarms" }, { name: "Tasks" },
        { name: "Calendar" }, { name: "Wake logs" }, { name: "Notifications" }
      ],
      components: {
        securitySchemes: { bearer: { type: :http, scheme: :bearer, bearerFormat: "JWT" } },
        schemas: {
          Error: {
            type: :object,
            properties: {
              error: { type: :string },
              details: { type: :object, additionalProperties: { type: :array, items: { type: :string } } }
            },
            required: ["error"]
          },
          User: {
            type: :object,
            properties: {
              id: { type: :integer },
              email: { type: :string, nullable: true },
              name: { type: :string, nullable: true },
              created_at: timestamp,
              providers: { type: :array, items: { type: :string, enum: %w[google apple] } },
              avatar_url: { type: :string, nullable: true },
              google_connected: { type: :boolean },
              google_calendar_synced_at: nullable_timestamp
            },
            required: %w[id providers google_connected]
          },
          AuthResponse: {
            type: :object,
            properties: { token: { type: :string }, user: { "$ref" => "#/components/schemas/User" } },
            required: %w[token user]
          },
          Alarm: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              time: { type: :string, example: "06:30", pattern: "^([01]\\d|2[0-3]):[0-5]\\d$" },
              repeat_days: { type: :array, items: { type: :integer, minimum: 1, maximum: 7 },
                             description: "ISO weekdays, 1 = Monday. Empty = rings once." },
              enabled: { type: :boolean },
              sound: { type: :string, enum: Alarm::SOUNDS },
              volume: { type: :integer, minimum: 0, maximum: 100 },
              gradual_volume: { type: :boolean },
              vibration: { type: :boolean },
              snooze_minutes: { type: :integer, minimum: 0, maximum: 60, description: "0 disables snooze" },
              snooze_limit: { type: :integer, minimum: 0, maximum: 10, description: "0 = unlimited" },
              wake_up_check: { type: :boolean },
              challenge_type: { type: :string, enum: Alarm::CHALLENGE_TYPES },
              challenge_difficulty: { type: :string, enum: Alarm::CHALLENGE_DIFFICULTIES },
              qr_code: { type: :string, nullable: true, description: "Required when challenge_type is qr" }
            },
            required: %w[id title time repeat_days enabled]
          },
          AlarmInput: {
            type: :object,
            properties: {
              alarm: {
                type: :object,
                properties: {
                  title: { type: :string }, time: { type: :string, example: "06:30" },
                  repeat_days: { type: :array, items: { type: :integer } }, enabled: { type: :boolean },
                  sound: { type: :string }, volume: { type: :integer }, gradual_volume: { type: :boolean },
                  vibration: { type: :boolean }, snooze_minutes: { type: :integer }, snooze_limit: { type: :integer },
                  wake_up_check: { type: :boolean }, challenge_type: { type: :string },
                  challenge_difficulty: { type: :string }, qr_code: { type: :string }
                }
              }
            },
            required: ["alarm"]
          },
          Task: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              priority: { type: :string, enum: Task::PRIORITIES },
              status: { type: :string, enum: Task::STATUSES },
              due_at: nullable_timestamp,
              reminder_at: nullable_timestamp,
              completed_at: nullable_timestamp,
              created_at: timestamp
            },
            required: %w[id title priority status]
          },
          TaskInput: {
            type: :object,
            properties: {
              task: {
                type: :object,
                properties: {
                  title: { type: :string }, description: { type: :string }, priority: { type: :string },
                  status: { type: :string }, due_at: timestamp, reminder_at: timestamp
                }
              }
            },
            required: ["task"]
          },
          CalendarEvent: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              location: { type: :string, nullable: true },
              start_at: timestamp,
              end_at: nullable_timestamp,
              all_day: { type: :boolean },
              source: { type: :string, enum: CalendarEvent::SOURCES }
            },
            required: %w[id title start_at source]
          },
          CalendarEventInput: {
            type: :object,
            properties: {
              calendar_event: {
                type: :object,
                properties: {
                  title: { type: :string }, description: { type: :string }, location: { type: :string },
                  start_at: timestamp, end_at: timestamp, all_day: { type: :boolean }
                }
              }
            },
            required: ["calendar_event"]
          },
          WakeLog: {
            type: :object,
            properties: {
              id: { type: :integer },
              alarm_id: { type: :integer, nullable: true },
              alarm_title: { type: :string, nullable: true },
              scheduled_at: nullable_timestamp,
              dismissed_at: timestamp,
              snooze_count: { type: :integer },
              challenge_type: { type: :string, nullable: true },
              mission_seconds: { type: :integer, nullable: true }
            },
            required: %w[id dismissed_at snooze_count]
          },
          Notification: {
            type: :object,
            properties: {
              id: { type: :integer }, title: { type: :string }, body: { type: :string, nullable: true },
              read: { type: :boolean }, created_at: timestamp
            },
            required: %w[id title read]
          }
        }
      }
    }
  }
end
