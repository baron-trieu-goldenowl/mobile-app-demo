module Api
  module V1
    class NotificationsController < BaseController
      LIMIT = 100

      # GET /api/v1/notifications
      def index
        notifications = current_user.notifications.recent_first.limit(LIMIT)
        render json: NotificationBlueprint.render(notifications, root: :notifications)
      end

      # PATCH /api/v1/notifications/:id/read
      def read
        notification = current_user.notifications.find(params[:id])
        notification.update!(read: true)
        render json: NotificationBlueprint.render(notification, root: :notification)
      end

      # PATCH /api/v1/notifications/read_all
      def read_all
        # Bulk flag change; no callbacks or validations involved.
        current_user.notifications.unread.update_all(read: true, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
        head :no_content
      end
    end
  end
end
