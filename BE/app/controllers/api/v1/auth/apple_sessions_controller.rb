module Api
  module V1
    module Auth
      class AppleSessionsController < BaseController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/apple
        # body: { identity_token, authorization_code?, name? }
        def create
          user = ::Auth::AppleSignIn.call(identity_token: params[:identity_token],
                                          authorization_code: params[:authorization_code],
                                          name: params[:name])
          render json: { token: user.auth_token, user: UserBlueprint.render_as_hash(user) }
        rescue Apple::Error => e
          render_error(e.message, :unauthorized)
        end
      end
    end
  end
end
