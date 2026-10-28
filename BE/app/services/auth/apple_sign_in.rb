module Auth
  class AppleSignIn < ApplicationService
    # name: Apple only sends the user's name to the app on the first sign-in.
    def initialize(identity_token:, authorization_code: nil, name: nil)
      super()
      @identity_token = identity_token
      @authorization_code = authorization_code
      @name = name
    end

    def call
      claims = Apple::IdentityToken.verify!(@identity_token)
      IdentitySignIn.call(
        provider: "apple",
        uid: claims["sub"],
        email: claims["email"],
        name: @name.presence,
        refresh_token: Apple::TokenClient.refresh_token_for(@authorization_code)
      )
    end
  end
end
