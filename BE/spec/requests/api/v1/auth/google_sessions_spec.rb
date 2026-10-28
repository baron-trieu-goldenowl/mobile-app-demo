require "rails_helper"

RSpec.describe "Google sign-in" do
  let(:claims) do
    { "aud" => "web-client", "iss" => "https://accounts.google.com", "exp" => 1.hour.from_now.to_i.to_s,
      "sub" => "google-123", "email" => "ana@gmail.com", "email_verified" => "true", "name" => "Ana" }
  end

  let(:calendar_items) do
    tomorrow = Date.tomorrow
    [
      { id: "e1", summary: "Standup", start: { dateTime: 1.day.from_now.iso8601 } },
      { id: "e2", summary: "Holiday", start: { date: tomorrow.to_s }, end: { date: (tomorrow + 1).to_s } },
      { id: "e3", status: "cancelled" }
    ]
  end

  before do
    stub_const("ENV", ENV.to_h.merge("GOOGLE_WEB_CLIENT_ID" => "web-client", "GOOGLE_WEB_CLIENT_SECRET" => "secret"))
    stub_request(:get, %r{oauth2.googleapis.com/tokeninfo}).to_return_json(body: claims)
    stub_request(:post, "https://oauth2.googleapis.com/token")
      .to_return_json(body: { access_token: "access", expires_in: 3600, refresh_token: "refresh" })
    stub_request(:get, %r{googleapis.com/calendar/v3}).to_return_json(body: { items: calendar_items })
  end

  it "signs in, links the calendar and imports events" do
    post "/api/v1/auth/google", params: { id_token: "token", server_auth_code: "code" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(json["user"]).to include("email" => "ana@gmail.com", "providers" => ["google"], "google_connected" => true)
    expect(CalendarEvent.from_google.pluck(:title)).to contain_exactly("Standup", "Holiday")
  end

  it "links to an existing account with the same email" do
    user = create(:user, email: "ana@gmail.com")

    post "/api/v1/auth/google", params: { id_token: "token" }, as: :json

    expect(json.dig("user", "id")).to eq(user.id)
    expect(user.identities.pluck(:provider)).to eq(["google"])
  end

  it "rejects tokens issued for another app" do
    stub_request(:get, %r{oauth2.googleapis.com/tokeninfo}).to_return_json(body: claims.merge("aud" => "evil"))

    post "/api/v1/auth/google", params: { id_token: "token" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
