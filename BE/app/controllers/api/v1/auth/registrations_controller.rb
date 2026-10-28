module Api
  module V1
    module Auth
      class RegistrationsController < BaseController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/signup
        def create
          user = User.create!(registration_params)
          render json: { token: user.auth_token, user: UserBlueprint.render_as_hash(user) }, status: :created
        end

        private

        def registration_params
          params.permit(:email, :password, :name)
        end
      end
    end
  end
end
