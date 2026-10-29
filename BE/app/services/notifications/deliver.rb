module Notifications
  # Creates an in-app notification of a known kind with its English text.
  #
  #   Notifications::Deliver.call(user, :calendar_synced, count: 12)
  #
  # `dedupe_for:` skips the notification when an unread one of the same kind
  # was created within that period (e.g. a sync failing on every refresh).
  class Deliver < ApplicationService
    TEMPLATES = {
      calendar_synced: {
        title: "Google Calendar synced",
        body: ->(data) { "Imported #{data[:count]} new or updated events." }
      },
      calendar_sync_failed: {
        title: "Google Calendar sync failed",
        body: ->(_data) { "We couldn't update your Google events. Reconnect Google Calendar in Settings." }
      },
      wake_streak: {
        title: ->(data) { "#{data[:days]}-day wake-up streak!" },
        body: ->(data) { "You've woken up with DayFlow #{data[:days]} days in a row. Keep it going!" }
      }
    }.freeze

    def initialize(user, kind, dedupe_for: nil, **data)
      super()
      @user = user
      @kind = kind.to_sym
      @data = data
      @dedupe_for = dedupe_for
    end

    # Returns the notification, or nil when deduplicated.
    def call
      return if duplicate?

      template = TEMPLATES.fetch(@kind)
      @user.notifications.create!(kind: @kind, data: @data,
                                  title: render(template[:title]), body: render(template[:body]))
    end

    private

    def duplicate?
      @dedupe_for && @user.notifications.unread.exists?(kind: @kind, created_at: @dedupe_for.ago..)
    end

    def render(text)
      text.respond_to?(:call) ? text.call(@data) : text
    end
  end
end
