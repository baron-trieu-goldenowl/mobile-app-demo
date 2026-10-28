module Accounts
  # Permanently deletes a user and all their data (App Store Review Guideline
  # 5.1.1(v)), revoking third-party tokens first.
  class Destroy < ApplicationService
    def initialize(user)
      super()
      @user = user
    end

    def call
      Google::OauthClient.revoke(@user.google_refresh_token) if @user.google_connected?
      @user.identities.where(provider: "apple").find_each do |identity|
        Apple::TokenClient.revoke(identity.refresh_token)
      end
      @user.destroy!
    end
  end
end
