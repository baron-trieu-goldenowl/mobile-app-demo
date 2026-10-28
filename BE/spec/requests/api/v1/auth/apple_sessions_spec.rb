require "rails_helper"

RSpec.describe "Sign in with Apple" do
  let(:key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:jwk) { JWT::JWK.new(key, kid: "apple-kid") }
  let(:audience) { "com.dayflow.app" }

  def identity_token(aud: audience, sub: "apple-001")
    payload = { iss: "https://appleid.apple.com", aud: aud, sub: sub, email: "relay@privaterelay.appleid.com",
                exp: 10.minutes.from_now.to_i, iat: Time.current.to_i }
    JWT.encode(payload, jwk.signing_key, "RS256", kid: jwk.kid)
  end

  before do
    Rails.cache.clear
    stub_request(:get, "https://appleid.apple.com/auth/keys").to_return_json(body: { keys: [jwk.export] })
  end

  it "creates the account from a valid identity token" do
    post "/api/v1/auth/apple", params: { identity_token: identity_token, name: "Bao" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(json["user"]).to include("name" => "Bao", "providers" => ["apple"])
  end

  it "signs the same Apple user into the same account" do
    2.times { post "/api/v1/auth/apple", params: { identity_token: identity_token }, as: :json }

    expect(User.count).to eq(1)
  end

  it "rejects tokens for another bundle id" do
    post "/api/v1/auth/apple", params: { identity_token: identity_token(aud: "com.other") }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
