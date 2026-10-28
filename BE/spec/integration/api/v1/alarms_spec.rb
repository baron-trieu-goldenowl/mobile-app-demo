require "swagger_helper"

RSpec.describe "Alarms API" do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{user.auth_token}" }
  let(:alarm_record) { create(:alarm, user: user) }

  path "/api/v1/alarms" do
    get "List alarms (ordered by time)" do
      tags "Alarms"
      security [{ bearer: [] }]
      produces "application/json"

      response "200", "alarms" do
        schema type: :object,
               properties: { alarms: { type: :array, items: { "$ref" => "#/components/schemas/Alarm" } } },
               required: ["alarms"]
        before { alarm_record }

        run_test!
      end
    end

    post "Create an alarm" do
      tags "Alarms"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/AlarmInput" }

      response "201", "created" do
        schema type: :object, properties: { alarm: { "$ref" => "#/components/schemas/Alarm" } }, required: ["alarm"]
        let(:body) do
          { alarm: { title: "Wake up", time: "06:30", repeat_days: [1, 2, 3, 4, 5],
                     challenge_type: "math", challenge_difficulty: "medium", wake_up_check: true } }
        end

        run_test!
      end

      response "422", "invalid alarm" do
        schema "$ref" => "#/components/schemas/Error"
        let(:body) { { alarm: { title: "", time: "25:00" } } }

        run_test!
      end
    end
  end

  path "/api/v1/alarms/{id}" do
    parameter name: :id, in: :path, type: :integer

    patch "Update an alarm (e.g. toggle `enabled`)" do
      tags "Alarms"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/AlarmInput" }

      response "200", "updated" do
        schema type: :object, properties: { alarm: { "$ref" => "#/components/schemas/Alarm" } }, required: ["alarm"]
        let(:id) { alarm_record.id }
        let(:body) { { alarm: { enabled: false } } }

        run_test!
      end

      response "404", "not found (or another user's alarm)" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { create(:alarm).id }
        let(:body) { { alarm: { enabled: false } } }

        run_test!
      end
    end

    delete "Delete an alarm" do
      tags "Alarms"
      security [{ bearer: [] }]

      response "204", "deleted" do
        let(:id) { alarm_record.id }

        run_test!
      end
    end
  end
end
