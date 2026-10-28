require "rails_helper"

RSpec.describe "Account deletion" do
  it "deletes the user and all their data" do
    user = create(:user, google_refresh_token: "refresh")
    create(:alarm, user: user)
    create(:task, user: user)
    revoke = stub_request(:post, "https://oauth2.googleapis.com/revoke").to_return(status: 200, body: "{}")

    delete "/api/v1/account", headers: auth_headers(user)

    expect(response).to have_http_status(:no_content)
    expect(User.exists?(user.id)).to be(false)
    expect(Alarm.count + Task.count).to eq(0)
    expect(revoke).to have_been_requested
  end
end
