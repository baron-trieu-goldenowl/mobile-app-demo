require "swagger_helper"

RSpec.describe "Notifications API" do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{user.auth_token}" }
  let(:notification) { user.notifications.create!(title: "Welcome", body: "Set your first alarm") }

  path "/api/v1/notifications" do
    get "Latest 100 notifications" do
      tags "Notifications"
      security [{ bearer: [] }]
      produces "application/json"

      response "200", "notifications" do
        schema type: :object,
               properties: { notifications: { type: :array,
                                              items: { "$ref" => "#/components/schemas/Notification" } } },
               required: ["notifications"]
        before { notification }

        run_test!
      end
    end
  end

  path "/api/v1/notifications/{id}/read" do
    parameter name: :id, in: :path, type: :integer

    patch "Mark one notification as read" do
      tags "Notifications"
      security [{ bearer: [] }]
      produces "application/json"

      response "200", "marked as read" do
        schema type: :object, properties: { notification: { "$ref" => "#/components/schemas/Notification" } }
        let(:id) { notification.id }

        run_test!
      end
    end
  end

  path "/api/v1/notifications/read_all" do
    patch "Mark all notifications as read" do
      tags "Notifications"
      security [{ bearer: [] }]

      response "204", "done" do
        run_test!
      end
    end
  end
end
