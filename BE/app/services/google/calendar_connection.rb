module Google
  # Stores / refreshes / removes a user's Google Calendar OAuth tokens.
  class CalendarConnection
    def initialize(user)
      @user = user
    end

    def connect!(server_auth_code)
      store_tokens!(OauthClient.exchange_code(server_auth_code))
    end

    # A valid access token, refreshed shortly before it expires.
    def access_token!
      raise Error, "Google Calendar is not connected" unless @user.google_connected?

      store_tokens!(OauthClient.refresh_access_token(@user.google_refresh_token)) if access_token_expired?
      @user.google_access_token
    end

    def expire_access_token!
      @user.update!(google_token_expires_at: nil)
    end

    def disconnect!
      OauthClient.revoke(@user.google_refresh_token) if @user.google_connected?
      @user.transaction do
        @user.calendar_events.from_google.delete_all
        @user.update!(google_refresh_token: nil, google_access_token: nil,
                      google_token_expires_at: nil, google_calendar_synced_at: nil)
      end
    end

    private

    def access_token_expired?
      @user.google_access_token.blank? ||
        @user.google_token_expires_at.nil? ||
        @user.google_token_expires_at < 1.minute.from_now
    end

    def store_tokens!(tokens)
      attributes = {
        google_access_token: tokens["access_token"],
        google_token_expires_at: tokens["expires_in"].to_i.seconds.from_now
      }
      attributes[:google_refresh_token] = tokens["refresh_token"] if tokens["refresh_token"].present?
      @user.update!(attributes)
    end
  end
end
