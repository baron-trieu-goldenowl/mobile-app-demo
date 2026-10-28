require "swagger_helper"

RSpec.describe "Profile API" do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{user.auth_token}" }

  path "/api/v1/profile" do
    get "Current user" do
      tags "Profile"
      security [{ bearer: [] }]
      produces "application/json"

      response "200", "profile" do
        schema type: :object, properties: { user: { "$ref" => "#/components/schemas/User" } }, required: ["user"]
        run_test!
      end

      response "401", "missing or invalid token" do
        schema "$ref" => "#/components/schemas/Error"
        let(:Authorization) { "Bearer invalid" }

        run_test!
      end
    end

    patch "Update name / email (send multipart/form-data with `avatar` to change the photo)" do
      tags "Profile"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object, properties: { name: { type: :string }, email: { type: :string } }
      }

      response "200", "updated" do
        schema type: :object, properties: { user: { "$ref" => "#/components/schemas/User" } }, required: ["user"]
        let(:body) { { name: "New name" } }

        run_test!
      end

      response "422", "invalid email" do
        schema "$ref" => "#/components/schemas/Error"
        let(:body) { { email: "not-an-email" } }

        run_test!
      end
    end
  end

  path "/api/v1/account" do
    delete "Permanently delete the account and all data" do
      tags "Profile"
      description "Revokes Google / Apple tokens, then deletes the user (App Store Guideline 5.1.1(v))."
      security [{ bearer: [] }]

      response "204", "deleted" do
        run_test!
      end
    end
  end
end
