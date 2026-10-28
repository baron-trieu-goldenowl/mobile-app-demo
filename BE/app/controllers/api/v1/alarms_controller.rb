module Api
  module V1
    class AlarmsController < BaseController
      before_action :set_alarm, only: %i[update destroy]

      # GET /api/v1/alarms
      def index
        render json: AlarmBlueprint.render(current_user.alarms.chronological, root: :alarms)
      end

      # POST /api/v1/alarms
      def create
        alarm = current_user.alarms.create!(alarm_params)
        render json: AlarmBlueprint.render(alarm, root: :alarm), status: :created
      end

      # PATCH /api/v1/alarms/:id
      def update
        @alarm.update!(alarm_params)
        render json: AlarmBlueprint.render(@alarm, root: :alarm)
      end

      # DELETE /api/v1/alarms/:id
      def destroy
        @alarm.destroy!
        head :no_content
      end

      private

      def set_alarm
        @alarm = current_user.alarms.find(params[:id])
      end

      def alarm_params
        params.require(:alarm).permit(
          :title, :time, :enabled, :sound, :volume, :gradual_volume, :vibration,
          :snooze_minutes, :snooze_limit, :wake_up_check,
          :challenge_type, :challenge_difficulty, :qr_code, repeat_days: []
        )
      end
    end
  end
end
