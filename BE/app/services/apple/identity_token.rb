module Apple
  # Verifies "Sign in with Apple" identity tokens against Apple's public keys.
  #
  # ENV: APPLE_BUNDLE_ID (default com.dayflow.app) – the token audience.
  module IdentityToken
    ISSUER = "https://appleid.apple.com".freeze
    KEYS_URL = "https://appleid.apple.com/auth/keys".freeze
    CACHE_KEY = "apple/jwks".freeze

    module_function

    # Returns the claims ("sub", "email", ...) of a valid token.
    def verify!(token)
      raise Error, "Missing Apple identity token" if token.blank?

      claims, = JWT.decode(token, nil, true,
                           algorithms: ["RS256"],
                           jwks: method(:jwks),
                           iss: ISSUER, verify_iss: true,
                           aud: bundle_id, verify_aud: true)
      claims
    rescue JWT::DecodeError => e
      raise Error, "Invalid Apple identity token: #{e.message}"
    end

    # JWKS loader; refetches when Apple rotated its keys.
    def jwks(options = {})
      Rails.cache.delete(CACHE_KEY) if options[:kid_not_found]
      keys = Rails.cache.fetch(CACHE_KEY, expires_in: 12.hours) { ExternalHttp.get_json(KEYS_URL) }
      JWT::JWK::Set.new(keys)
    rescue ExternalHttp::Error => e
      raise Error, "Could not fetch Apple keys: #{e.message}"
    end

    def bundle_id
      ENV.fetch("APPLE_BUNDLE_ID", "com.dayflow.app")
    end
  end
end
