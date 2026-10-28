require "swagger_helper"

RSpec.describe "Auth API" do
  path "/api/v1/auth/signup" do
    post "Create an account with email and password" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: "me@example.com" },
          password: { type: :string, example: "Password1", description: "8+ chars, upper, lower and digit" },
          name: { type: :string, example: "Minh An" }
        },
        required: %w[email password]
      }

      response "201", "account created" do
        schema "$ref" => "#/components/schemas/AuthResponse"
        let(:body) { { email: "new@example.com", password: "Password1", name: "New" } }

        run_test!
      end

      response "422", "invalid data" do
        schema "$ref" => "#/components/schemas/Error"
        let(:body) { { email: "bad", password: "weak" } }

        run_test!
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Log in with email and password" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { email: { type: :string }, password: { type: :string } },
        required: %w[email password]
      }

      before { create(:user, email: "me@example.com") }

      response "200", "logged in" do
        schema "$ref" => "#/components/schemas/AuthResponse"
        let(:body) { { email: "me@example.com", password: "Password1" } }

        run_test!
      end

      response "401", "wrong credentials" do
        schema "$ref" => "#/components/schemas/Error"
        let(:body) { { email: "me@example.com", password: "Wrong1234" } }

        run_test!
      end
    end
  end

  path "/api/v1/auth/google" do
    post "Sign in with Google" do
      tags "Auth"
      description "Verifies the Google ID token. When `server_auth_code` is sent (Calendar scope granted), " \
                  "the refresh token is stored and the Google Calendar is imported."
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { id_token: { type: :string }, server_auth_code: { type: :string, nullable: true } },
        required: ["id_token"]
      }

      let(:body) { { id_token: "google-id-token" } }

      before { stub_const("ENV", ENV.to_h.merge("GOOGLE_WEB_CLIENT_ID" => "web-client")) }

      response "200", "signed in" do
        schema "$ref" => "#/components/schemas/AuthResponse"
        before do
          claims = { aud: "web-client", iss: "https://accounts.google.com", exp: 1.hour.from_now.to_i.to_s,
                     sub: "google-1", email: "ana@gmail.com", email_verified: "true", name: "Ana" }
          stub_request(:get, %r{oauth2.googleapis.com/tokeninfo}).to_return_json(body: claims)
        end

        run_test!
      end

      response "401", "invalid Google token" do
        schema "$ref" => "#/components/schemas/Error"
        before { stub_request(:get, %r{oauth2.googleapis.com/tokeninfo}).to_return(status: 400, body: "{}") }

        run_test!
      end
    end
  end

  path "/api/v1/auth/apple" do
    post "Sign in with Apple" do
      tags "Auth"
      description "Verifies the Apple identity token against Apple's public keys. " \
                  "`name` is only provided by Apple on the first sign-in."
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          identity_token: { type: :string },
          authorization_code: { type: :string, nullable: true },
          name: { type: :string, nullable: true }
        },
        required: ["identity_token"]
      }

      let(:key) { JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: "apple-kid") }
      let(:aud) { "com.dayflow.app" }
      let(:body) do
        payload = { iss: "https://appleid.apple.com", aud: aud, sub: "apple-1", email: "x@privaterelay.appleid.com",
                    exp: 10.minutes.from_now.to_i }
        { identity_token: JWT.encode(payload, key.signing_key, "RS256", kid: key.kid), name: "Bao" }
      end

      before do
        Rails.cache.clear
        stub_request(:get, "https://appleid.apple.com/auth/keys").to_return_json(body: { keys: [key.export] })
      end

      response "200", "signed in" do
        schema "$ref" => "#/components/schemas/AuthResponse"
        run_test!
      end

      response "401", "invalid Apple token" do
        schema "$ref" => "#/components/schemas/Error"
        let(:aud) { "com.other.app" }

        run_test!
      end
    end
  end
end
