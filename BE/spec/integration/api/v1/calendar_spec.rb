require "swagger_helper"

RSpec.describe "Calendar API" do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{user.auth_token}" }
  let(:event_record) { create(:calendar_event, user: user) }

  path "/api/v1/calendar_events" do
    get "List events (local + imported Google events)" do
      tags "Calendar"
      security [{ bearer: [] }]
      produces "application/json"
      parameter name: :from, in: :query, schema: { type: :string, format: "date-time" }, required: false
      parameter name: :to, in: :query, schema: { type: :string, format: "date-time" }, required: false

      response "200", "events" do
        schema type: :object,
               properties: { calendar_events: { type: :array,
                                                items: { "$ref" => "#/components/schemas/CalendarEvent" } } },
               required: ["calendar_events"]
        before { event_record }

        run_test!
      end
    end

    post "Create a personal event" do
      tags "Calendar"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/CalendarEventInput" }

      response "201", "created" do
        schema type: :object, properties: { calendar_event: { "$ref" => "#/components/schemas/CalendarEvent" } }
        let(:body) { { calendar_event: { title: "Lunch", start_at: 1.hour.from_now.iso8601 } } }

        run_test!
      end
    end
  end

  path "/api/v1/calendar_events/{id}" do
    parameter name: :id, in: :path, type: :integer

    patch "Update a personal event (Google events are read-only)" do
      tags "Calendar"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/CalendarEventInput" }
      let(:body) { { calendar_event: { title: "Renamed" } } }

      response "200", "updated" do
        schema type: :object, properties: { calendar_event: { "$ref" => "#/components/schemas/CalendarEvent" } }
        let(:id) { event_record.id }

        run_test!
      end

      response "404", "Google event or not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { create(:calendar_event, :google, user: user).id }

        run_test!
      end
    end

    delete "Delete a personal event" do
      tags "Calendar"
      security [{ bearer: [] }]

      response "204", "deleted" do
        let(:id) { event_record.id }

        run_test!
      end
    end
  end

  path "/api/v1/calendar_sync" do
    post "Import the user's Google Calendar now" do
      tags "Calendar"
      security [{ bearer: [] }]
      produces "application/json"

      response "422", "Google Calendar not connected" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end

  path "/api/v1/google_connection" do
    post "Link Google Calendar to the current account" do
      tags "Calendar"
      description "Exchanges a server auth code from the Google SDK, stores the refresh token and imports events."
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object, properties: { server_auth_code: { type: :string } }, required: ["server_auth_code"]
      }

      response "200", "connected" do
        schema type: :object,
               properties: { imported: { type: :integer }, user: { "$ref" => "#/components/schemas/User" } }
        let(:body) { { server_auth_code: "code" } }

        before do
          stub_const("ENV", ENV.to_h.merge("GOOGLE_WEB_CLIENT_ID" => "web", "GOOGLE_WEB_CLIENT_SECRET" => "secret"))
          stub_request(:post, "https://oauth2.googleapis.com/token")
            .to_return_json(body: { access_token: "access", expires_in: 3600, refresh_token: "refresh" })
          stub_request(:get, %r{googleapis.com/calendar/v3}).to_return_json(body: { items: [] })
        end

        run_test!
      end
    end

    delete "Unlink Google Calendar (removes imported events, revokes the token)" do
      tags "Calendar"
      security [{ bearer: [] }]
      produces "application/json"

      response "200", "disconnected" do
        schema type: :object, properties: { user: { "$ref" => "#/components/schemas/User" } }
        run_test!
      end
    end
  end
end
