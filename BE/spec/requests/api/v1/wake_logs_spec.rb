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

  it "notifies a wake-up streak milestone" do
    2.downto(1) { |n| create_log(n.days.ago) }

    post "/api/v1/wake_logs", params: { wake_log: { dismissed_at: Time.current }, utc_offset: 0 },
                              headers: auth_headers(user), as: :json

    expect(user.notifications.last).to have_attributes(kind: "wake_streak", data: { "days" => 3 })
  end

  def create_log(time)
    user.wake_logs.create!(dismissed_at: time, snooze_count: 0)
  end
end
