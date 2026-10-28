require "rails_helper"

RSpec.describe "Calendar events" do
  let(:user) { create(:user) }

  it "creates local events even if another source is sent" do
    params = { calendar_event: { title: "Lunch", start_at: 1.hour.from_now, source: "google_calendar" } }

    post "/api/v1/calendar_events", params: params, headers: auth_headers(user), as: :json

    expect(json.dig("calendar_event", "source")).to eq("local")
  end

  it "keeps Google events read-only" do
    event = create(:calendar_event, :google, user: user)

    delete "/api/v1/calendar_events/#{event.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:not_found)
  end
end
