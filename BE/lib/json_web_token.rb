# Signs and verifies the API access tokens handed to the mobile app.
module JsonWebToken
  ALGORITHM = "HS256".freeze
  EXPIRATION = 30.days

  module_function

  def encode(payload, expires_at: EXPIRATION.from_now)
    JWT.encode(payload.merge(exp: expires_at.to_i), secret, ALGORITHM)
  end

  # Returns the payload, or nil when the token is invalid or expired.
  def decode(token)
    JWT.decode(token, secret, true, algorithm: ALGORITHM).first
  rescue JWT::DecodeError
    nil
  end

  def secret
    Rails.application.secret_key_base
  end
end
