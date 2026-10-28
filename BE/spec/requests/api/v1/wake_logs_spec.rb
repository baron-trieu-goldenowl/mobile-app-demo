require "rails_helper"

RSpec.describe "Wake logs" do
  let(:user) { create(:user) }

  it "records a wake-up and lists it" do
    alarm = create(:alarm, user: user)
    params = { wake_log: { alarm_id: alarm.id, alarm_title: alarm.title, dismissed_at: Time.current, snooze_count: 1 } }

    post "/api/v1/wake_logs", params: params, headers: auth_headers(user), as: :json
    get "/api/v1/wake_logs", headers: auth_headers(user)

    expect(json["wake_logs"].first).to include("alarm_id" => alarm.id, "snooze_count" => 1)
  end

  it "refuses another user's alarm" do
    params = { wake_log: { alarm_id: create(:alarm).id, dismissed_at: Time.current } }

    post "/api/v1/wake_logs", params: params, headers: auth_headers(user), as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end
end
