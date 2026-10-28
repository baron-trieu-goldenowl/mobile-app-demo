module Auth
  # Native Google Sign-In: verifies the ID token and, when the user granted
  # Calendar access, stores the refresh token and imports the calendar.
  class GoogleSignIn < ApplicationService
    def initialize(id_token:, server_auth_code: nil)
      super()
      @id_token = id_token
      @server_auth_code = server_auth_code
    end

    def call
      claims = Google::OauthClient.verify_id_token(@id_token)
      user = IdentitySignIn.call(provider: "google", uid: claims["sub"], email: claims["email"], name: claims["name"])
      connect_calendar(user) if @server_auth_code.present?
      user
    end

    private

    # Signing in must not fail because the first calendar import did.
    def connect_calendar(user)
      Google::CalendarConnection.new(user).connect!(@server_auth_code)
      Google::CalendarSync.call(user)
    rescue Google::Error => e
      Rails.logger.warn("Google Calendar setup failed for user #{user.id}: #{e.message}")
    end
  end
end
