module Api
  module V1
    module Auth
      class GoogleSessionsController < BaseController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/google
        # body: { id_token, server_auth_code? }
        def create
          user = ::Auth::GoogleSignIn.call(id_token: params[:id_token], server_auth_code: params[:server_auth_code])
          render json: { token: user.auth_token, user: UserBlueprint.render_as_hash(user) }
        rescue Google::Error => e
          render_error(e.message, :unauthorized)
        end
      end
    end
  end
end
