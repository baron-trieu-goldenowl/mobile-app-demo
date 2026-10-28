require "rails_helper"

RSpec.describe "Email authentication" do
  describe "POST /api/v1/auth/signup" do
    it "creates the account and returns a token" do
      post "/api/v1/auth/signup", params: { email: "new@example.com", password: "Password1", name: "New" }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["token"]).to be_present
      expect(json["user"]).to include("email" => "new@example.com", "providers" => [], "google_connected" => false)
      expect(json["user"].keys).not_to include("password_digest", "google_refresh_token")
    end

    it "rejects weak passwords" do
      post "/api/v1/auth/signup", params: { email: "new@example.com", password: "weak" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["details"]).to have_key("password")
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "me@example.com") }

    it "logs in case-insensitively" do
      post "/api/v1/auth/login", params: { email: "ME@example.com", password: "Password1" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json.dig("user", "id")).to eq(user.id)
    end

    it "rejects a wrong password" do
      post "/api/v1/auth/login", params: { email: "me@example.com", password: "Nope12345" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  it "rejects requests without a valid token" do
    get "/api/v1/alarms", headers: { "Authorization" => "Bearer nope" }

    expect(response).to have_http_status(:unauthorized)
  end
end
