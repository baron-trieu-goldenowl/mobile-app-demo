require "openssl"

module Apple
  # Apple's token endpoints, used to obtain a refresh token at sign-in and to
  # revoke it when the account is deleted (required by App Store Review
  # Guideline 5.1.1(v) for apps offering Sign in with Apple).
  #
  # ENV: APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY (contents of the .p8
  # "Sign in with Apple" key), APPLE_BUNDLE_ID.
  module TokenClient
    TOKEN_URL = "https://appleid.apple.com/auth/token".freeze
    REVOKE_URL = "https://appleid.apple.com/auth/revoke".freeze

    module_function

    def configured?
      %w[APPLE_TEAM_ID APPLE_KEY_ID APPLE_PRIVATE_KEY].all? { |key| ENV[key].present? }
    end

    # Returns the refresh token, or nil when not configured / not possible.
    def refresh_token_for(authorization_code)
      return if authorization_code.blank? || !configured?

      ExternalHttp.post_form(TOKEN_URL, client_id: IdentityToken.bundle_id, client_secret: client_secret,
                                        code: authorization_code, grant_type: "authorization_code")["refresh_token"]
    rescue ExternalHttp::Error => e
      Rails.logger.warn("Apple code exchange failed: #{e.message}")
      nil
    end

    def revoke(refresh_token)
      return if refresh_token.blank? || !configured?

      ExternalHttp.post_form(REVOKE_URL, client_id: IdentityToken.bundle_id, client_secret: client_secret,
                                         token: refresh_token, token_type_hint: "refresh_token")
    rescue ExternalHttp::Error => e
      Rails.logger.warn("Apple revoke failed: #{e.message}")
    end

    def client_secret
      key = OpenSSL::PKey::EC.new(ENV.fetch("APPLE_PRIVATE_KEY").gsub("\\n", "\n"))
      payload = { iss: ENV.fetch("APPLE_TEAM_ID"), iat: Time.current.to_i, exp: 5.minutes.from_now.to_i,
                  aud: IdentityToken::ISSUER, sub: IdentityToken.bundle_id }
      JWT.encode(payload, key, "ES256", kid: ENV.fetch("APPLE_KEY_ID"))
    end
  end
end
