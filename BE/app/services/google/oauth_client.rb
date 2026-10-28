module Google
  # Google OAuth 2.0 endpoints.
  #
  # ENV:
  #   GOOGLE_WEB_CLIENT_ID      "Web application" client; the app passes it as
  #                             serverClientId, so ID tokens are issued for it
  #                             and server auth codes are redeemable with it.
  #   GOOGLE_WEB_CLIENT_SECRET  secret of the web client.
  #   GOOGLE_IOS_CLIENT_ID      optional extra accepted ID token audience.
  #   GOOGLE_ANDROID_CLIENT_ID  optional extra accepted ID token audience.
  module OauthClient
    TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo".freeze
    TOKEN_URL = "https://oauth2.googleapis.com/token".freeze
    REVOKE_URL = "https://oauth2.googleapis.com/revoke".freeze
    ISSUERS = %w[accounts.google.com https://accounts.google.com].freeze

    module_function

    # Verifies an ID token with Google and returns its claims
    # ("sub", "email", "name", ...).
    def verify_id_token(id_token)
      raise Error, "Missing Google ID token" if id_token.blank?

      claims = request { ExternalHttp.get_json(TOKENINFO_URL, params: { id_token: id_token }) }
      raise Error, "Google token was issued for another app" unless audiences.include?(claims["aud"])
      raise Error, "Invalid Google token issuer" unless ISSUERS.include?(claims["iss"])
      raise Error, "Google token expired" if claims["exp"].to_i < Time.current.to_i
      raise Error, "Google email is not verified" unless claims["email_verified"].to_s == "true"

      claims
    end

    # Exchanges a one-time server auth code from the mobile SDK for tokens.
    def exchange_code(code)
      raise Error, "Missing Google authorization code" if code.blank?

      # Codes minted by the iOS / Android SDKs carry no redirect URI.
      request do
        ExternalHttp.post_form(TOKEN_URL, code: code, client_id: client_id, client_secret: client_secret,
                                          grant_type: "authorization_code", redirect_uri: "")
      end
    end

    def refresh_access_token(refresh_token)
      request do
        ExternalHttp.post_form(TOKEN_URL, refresh_token: refresh_token, client_id: client_id,
                                          client_secret: client_secret, grant_type: "refresh_token")
      end
    end

    # Best effort: the token may already be revoked or expired.
    def revoke(token)
      ExternalHttp.post_form(REVOKE_URL, token: token)
    rescue ExternalHttp::Error => e
      Rails.logger.info("Google revoke skipped: #{e.message}")
    end

    def request
      yield
    rescue ExternalHttp::Error => e
      raise Error, "Google: #{e.message}"
    end

    def client_id
      ENV.fetch("GOOGLE_WEB_CLIENT_ID") { raise Error, "GOOGLE_WEB_CLIENT_ID is not configured" }
    end

    def client_secret
      ENV.fetch("GOOGLE_WEB_CLIENT_SECRET") { raise Error, "GOOGLE_WEB_CLIENT_SECRET is not configured" }
    end

    def audiences
      [client_id, ENV.fetch("GOOGLE_IOS_CLIENT_ID", nil), ENV.fetch("GOOGLE_ANDROID_CLIENT_ID", nil)].compact_blank
    end
  end
end
