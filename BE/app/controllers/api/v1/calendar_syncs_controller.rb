module Api
  module V1
    class CalendarSyncsController < BaseController
      # POST /api/v1/calendar_sync — import the user's Google Calendar.
      def create
        imported = Google::CalendarSync.call(current_user)
        events = current_user.calendar_events.chronological
        render json: { imported: imported, calendar_events: CalendarEventBlueprint.render_as_hash(events) }
      rescue Google::Error => e
        render_error(e.message, :unprocessable_content)
      end
    end
  end
end
