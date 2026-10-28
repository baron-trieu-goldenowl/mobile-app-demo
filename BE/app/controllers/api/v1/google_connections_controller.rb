module Api
  module V1
    # Links / unlinks Google Calendar for the signed-in user (also used by
    # email and Apple accounts).
    class GoogleConnectionsController < BaseController
      # POST /api/v1/google_connection  body: { server_auth_code }
      def create
        Google::CalendarConnection.new(current_user).connect!(params.require(:server_auth_code))
        imported = Google::CalendarSync.call(current_user)
        render json: { imported: imported, user: UserBlueprint.render_as_hash(current_user.reload) }
      rescue Google::Error => e
        render_error(e.message, :unprocessable_content)
      end

      # DELETE /api/v1/google_connection
      def destroy
        Google::CalendarConnection.new(current_user).disconnect!
        render json: UserBlueprint.render(current_user.reload, root: :user)
      end
    end
  end
end
