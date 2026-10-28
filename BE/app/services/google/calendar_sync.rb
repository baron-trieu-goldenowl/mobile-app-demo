module Google
  # Imports the user's primary Google Calendar into calendar_events.
  #
  # Events are upserted by Google's event id; Google events inside the sync
  # window that no longer exist on Google are removed locally.
  class CalendarSync < ApplicationService
    EVENTS_URL = "https://www.googleapis.com/calendar/v3/calendars/primary/events".freeze
    PAST_WINDOW = 30.days
    FUTURE_WINDOW = 120.days
    MAX_PAGES = 10

    def initialize(user)
      super()
      @user = user
      @connection = CalendarConnection.new(user)
    end

    # Returns the number of events created or updated.
    def call
      window = (Time.current.beginning_of_day - PAST_WINDOW)..(Time.current.end_of_day + FUTURE_WINDOW)
      items = fetch_events(window).reject { |item| item["status"] == "cancelled" }

      changed = CalendarEvent.transaction do
        seen_ids, count = upsert_events(items)
        @user.calendar_events.from_google.where(start_at: window).where.not(external_id: seen_ids).delete_all
        count
      end

      @user.update!(google_calendar_synced_at: Time.current)
      changed
    end

    private

    # Returns [google ids kept, number of created / updated events].
    def upsert_events(items)
      seen_ids = []
      changed = 0
      items.each do |item|
        attributes = attributes_for(item)
        next unless attributes

        seen_ids << item["id"]
        event = @user.calendar_events.find_or_initialize_by(external_id: item["id"])
        event.assign_attributes(attributes)
        next unless event.changed?

        event.save!
        changed += 1
      end
      [seen_ids, changed]
    end

    def fetch_events(window)
      items = []
      page_token = nil
      MAX_PAGES.times do
        params = { timeMin: window.begin.iso8601, timeMax: window.end.iso8601,
                   singleEvents: true, orderBy: "startTime", maxResults: 250 }
        params[:pageToken] = page_token if page_token
        data = get_events(params)
        items.concat(data.fetch("items", []))
        page_token = data["nextPageToken"]
        break if page_token.blank?
      end
      items
    end

    def get_events(params, retried: false)
      headers = { "Authorization" => "Bearer #{@connection.access_token!}" }
      ExternalHttp.get_json(EVENTS_URL, params: params, headers: headers)
    rescue ExternalHttp::Error => e
      if e.status == 401 && !retried
        @connection.expire_access_token!
        return get_events(params, retried: true)
      end
      raise Error, "Google Calendar: #{e.message}"
    end

    def attributes_for(item)
      start_at = parse_time(item["start"])
      return unless start_at

      {
        title: item["summary"].presence || "(No title)",
        description: item["description"],
        location: item["location"],
        start_at: start_at,
        end_at: parse_time(item["end"]),
        all_day: item.dig("start", "date").present?,
        source: "google_calendar"
      }
    end

    def parse_time(node)
      return if node.blank?

      value = node["dateTime"].presence || node["date"].presence
      value && Time.zone.parse(value)
    end
  end
end
