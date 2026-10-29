module WakeLogs
  # Notifies the user when a new wake log extends their streak (consecutive
  # days with a wake-up) to a milestone. Days are counted in the device's
  # time zone, given as `utc_offset` seconds.
  class StreakMilestone < ApplicationService
    MILESTONES = [3, 7, 14, 30, 60, 100, 365].freeze

    def initialize(log, utc_offset: 0)
      super()
      @log = log
      @user = log.user
      @offset = utc_offset.to_i.clamp(-14.hours, 14.hours)
    end

    # Returns the streak notification, or nil.
    def call
      today = local_date(@log.dismissed_at)
      return unless first_wake_on?(today)

      streak = streak_ending(today, wake_days(since: today - MILESTONES.last))
      Notifications::Deliver.call(@user, :wake_streak, days: streak) if MILESTONES.include?(streak)
    end

    private

    def wake_days(since:)
      @user.wake_logs.since(since.beginning_of_day - @offset).pluck(:dismissed_at).to_set { |t| local_date(t) }
    end

    def first_wake_on?(date)
      start = date.beginning_of_day - @offset
      !@user.wake_logs.where(dismissed_at: start...@log.dismissed_at).where.not(id: @log.id).exists?
    end

    def streak_ending(date, days)
      count = 0
      count += 1 while days.include?(date - count)
      count
    end

    def local_date(time)
      (time.utc + @offset).to_date
    end
  end
end
