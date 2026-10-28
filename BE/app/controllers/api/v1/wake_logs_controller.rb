module Api
  module V1
    # Wake-up history used by the Report screen.
    class WakeLogsController < BaseController
      DEFAULT_DAYS = 30

      # GET /api/v1/wake_logs?days=30
      def index
        days = params.fetch(:days, DEFAULT_DAYS).to_i.clamp(1, 365)
        logs = current_user.wake_logs.since(days.days.ago.beginning_of_day).recent_first
        render json: WakeLogBlueprint.render(logs, root: :wake_logs)
      end

      # POST /api/v1/wake_logs
      def create
        log = current_user.wake_logs.create!(wake_log_params)
        render json: WakeLogBlueprint.render(log, root: :wake_log), status: :created
      end

      private

      def wake_log_params
        params.require(:wake_log).permit(:alarm_id, :alarm_title, :scheduled_at, :dismissed_at,
                                         :snooze_count, :challenge_type, :mission_seconds)
      end
    end
  end
end
