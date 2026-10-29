require "swagger_helper"

RSpec.describe "Wake logs API" do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{user.auth_token}" }

  path "/api/v1/wake_logs" do
    get "Wake-up history" do
      tags "Wake logs"
      security [{ bearer: [] }]
      produces "application/json"
      parameter name: :days, in: :query, schema: { type: :integer, default: 30, minimum: 1, maximum: 365 },
                required: false

      response "200", "history, newest first" do
        schema type: :object,
               properties: { wake_logs: { type: :array, items: { "$ref" => "#/components/schemas/WakeLog" } } },
               required: ["wake_logs"]
        let(:days) { 7 }

        before { user.wake_logs.create!(dismissed_at: 1.day.ago, snooze_count: 1) }

        run_test!
      end
    end

    post "Record a dismissed alarm" do
      tags "Wake logs"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          wake_log: {
            type: :object,
            properties: {
              alarm_id: { type: :integer }, alarm_title: { type: :string },
              scheduled_at: { type: :string, format: "date-time" },
              dismissed_at: { type: :string, format: "date-time" },
              snooze_count: { type: :integer }, challenge_type: { type: :string }, mission_seconds: { type: :integer }
            },
            required: ["dismissed_at"]
          },
          utc_offset: { type: :integer, example: 25_200,
                        description: "Device UTC offset in seconds, used to count wake-up streak days" }
        },
        required: ["wake_log"]
      }

      response "201", "recorded" do
        schema type: :object, properties: { wake_log: { "$ref" => "#/components/schemas/WakeLog" } }
        let(:body) do
          { wake_log: { alarm_title: "Wake up", dismissed_at: Time.current.iso8601, snooze_count: 0,
                        challenge_type: "math", mission_seconds: 30 } }
        end

        run_test!
      end
    end
  end
end
