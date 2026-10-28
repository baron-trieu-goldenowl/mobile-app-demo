module Api
  module V1
    module Auth
      class SessionsController < BaseController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/login
        def create
          user = User.find_by(email: params[:email].to_s.strip.downcase)
          if user&.authenticate(params[:password].to_s)
            render json: { token: user.auth_token, user: UserBlueprint.render_as_hash(user) }
          else
            render_error("Invalid email or password", :unauthorized)
          end
        end
      end
    end
  end
end
