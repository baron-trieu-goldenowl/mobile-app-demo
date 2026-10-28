module Api
  module V1
    class ProfilesController < BaseController
      # GET /api/v1/profile
      def show
        render json: UserBlueprint.render(current_user, root: :user)
      end

      # PATCH /api/v1/profile  (JSON or multipart with an avatar file)
      def update
        current_user.update!(profile_params)
        render json: UserBlueprint.render(current_user, root: :user)
      end

      private

      def profile_params
        params.permit(:name, :email, :avatar)
      end
    end
  end
end
