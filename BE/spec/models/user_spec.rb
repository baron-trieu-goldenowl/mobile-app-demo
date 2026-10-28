require "rails_helper"

RSpec.describe User do
  it "normalizes the email" do
    expect(create(:user, email: "  Me@Example.COM ").email).to eq("me@example.com")
  end

  it "requires a complex password for email accounts" do
    user = build(:user, password: "password")
    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "allows social accounts without a password" do
    user = described_class.new(email: "social@example.com")
    user.identities.build(provider: "apple", uid: "apple-1")
    expect(user).to be_valid
  end

  it "encrypts Google tokens at rest" do
    user = create(:user, google_refresh_token: "refresh-secret")
    raw = described_class.connection.select_value("SELECT google_refresh_token FROM users WHERE id = #{user.id}")
    expect(raw).not_to include("refresh-secret")
    expect(user.reload.google_refresh_token).to eq("refresh-secret")
  end
end
