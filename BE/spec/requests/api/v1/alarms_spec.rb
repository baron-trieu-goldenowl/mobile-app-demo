require "rails_helper"

RSpec.describe "Alarms" do
  let(:user) { create(:user) }

  it "lists only the current user's alarms, ordered by time" do
    create(:alarm, user: user, time: "08:00")
    create(:alarm, user: user, time: "06:00")
    create(:alarm)

    get "/api/v1/alarms", headers: auth_headers(user)

    expect(json["alarms"].pluck("time")).to eq(%w[06:00 08:00])
  end

  it "creates an alarm with mission options" do
    params = { alarm: { title: "Gym", time: "05:45", repeat_days: [1, 3], challenge_type: "typing",
                        challenge_difficulty: "hard", snooze_limit: 2, wake_up_check: true } }

    post "/api/v1/alarms", params: params, headers: auth_headers(user), as: :json

    expect(response).to have_http_status(:created)
    expect(json["alarm"]).to include("challenge_type" => "typing", "repeat_days" => [1, 3], "wake_up_check" => true)
  end

  it "returns validation details" do
    post "/api/v1/alarms", params: { alarm: { title: "", time: "25:00" } }, headers: auth_headers(user), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["details"].keys).to include("title", "time")
  end

  it "does not touch other users' alarms" do
    other = create(:alarm)

    delete "/api/v1/alarms/#{other.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:not_found)
  end
end
