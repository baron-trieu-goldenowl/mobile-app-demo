module Auth
  # Finds or creates the user for a verified external identity. An existing
  # account with the same (provider-verified) email is linked instead of
  # duplicated.
  class IdentitySignIn < ApplicationService
    def initialize(provider:, uid:, email:, name: nil, refresh_token: nil)
      super()
      @provider = provider
      @uid = uid
      @email = email&.downcase
      @name = name
      @refresh_token = refresh_token
    end

    def call
      identity = Identity.find_by(provider: @provider, uid: @uid)
      if identity
        identity.update!(refresh_token: @refresh_token) if @refresh_token.present?
        return identity.user
      end

      user = (@email.present? && User.find_by(email: @email)) || User.new(email: @email)
      user.name = @name if user.name.blank? && @name.present?
      user.identities.build(provider: @provider, uid: @uid, email: @email, refresh_token: @refresh_token)
      user.save!
      user
    end
  end
end
