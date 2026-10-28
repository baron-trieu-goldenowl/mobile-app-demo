module Api
  module V1
    class CalendarEventsController < BaseController
      # Google events are read-only; only local events can be changed.
      before_action :set_local_event, only: %i[update destroy]

      # GET /api/v1/calendar_events?from=...&to=...
      def index
        events = current_user.calendar_events.between(params[:from], params[:to]).chronological
        render json: CalendarEventBlueprint.render(events, root: :calendar_events)
      end

      # POST /api/v1/calendar_events
      def create
        event = current_user.calendar_events.local.create!(event_params)
        render json: CalendarEventBlueprint.render(event, root: :calendar_event), status: :created
      end

      # PATCH /api/v1/calendar_events/:id
      def update
        @event.update!(event_params)
        render json: CalendarEventBlueprint.render(@event, root: :calendar_event)
      end

      # DELETE /api/v1/calendar_events/:id
      def destroy
        @event.destroy!
        head :no_content
      end

      private

      def set_local_event
        @event = current_user.calendar_events.local.find(params[:id])
      end

      def event_params
        params.require(:calendar_event).permit(:title, :description, :location, :start_at, :end_at, :all_day)
      end
    end
  end
end
