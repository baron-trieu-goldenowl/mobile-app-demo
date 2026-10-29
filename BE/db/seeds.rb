# Idempotent seed data.
#
# Creates the App Store / Google Play review account with sample data so the
# reviewer can try every feature without setting anything up:
#   REVIEW_EMAIL=review@dayflow.app REVIEW_PASSWORD=Review1234 bin/rails db:seed

email = ENV.fetch("REVIEW_EMAIL", "review@dayflow.app")
password = ENV.fetch("REVIEW_PASSWORD") do
  raise "Set REVIEW_PASSWORD to seed the review account" if Rails.env.production?

  "Review1234"
end

reviewer = User.find_or_initialize_by(email: email)
reviewer.assign_attributes(name: "App Review", password: password)
reviewer.save!

if reviewer.alarms.none?
  reviewer.alarms.create!(title: "Wake up", time: "06:30", repeat_days: [1, 2, 3, 4, 5],
                          challenge_type: "math", challenge_difficulty: "easy", wake_up_check: true)
  reviewer.alarms.create!(title: "Weekend", time: "08:00", repeat_days: [6, 7], challenge_type: "shake")
  reviewer.alarms.create!(title: "Take medicine", time: "21:00", enabled: false, challenge_type: "typing")
end

if reviewer.tasks.none?
  tomorrow = Time.zone.tomorrow
  reviewer.tasks.create!(title: "Send weekly report", priority: "high", due_at: tomorrow.to_time.change(hour: 17))
  reviewer.tasks.create!(title: "Read 20 pages", priority: "low")
end

if reviewer.calendar_events.none?
  start = Time.zone.tomorrow.to_time.change(hour: 9)
  reviewer.calendar_events.create!(title: "Team standup", start_at: start, end_at: start + 15.minutes)
end

if reviewer.wake_logs.none?
  wake_up = reviewer.alarms.find_by(title: "Wake up")
  3.downto(1) do |days_ago|
    scheduled = days_ago.days.ago.change(hour: 6, min: 30)
    reviewer.wake_logs.create!(alarm: wake_up, alarm_title: "Wake up", scheduled_at: scheduled,
                               dismissed_at: scheduled + 4.minutes, snooze_count: days_ago == 2 ? 1 : 0,
                               challenge_type: "math", mission_seconds: 35)
  end
end

Notifications::Deliver.call(reviewer, :wake_streak, days: 3) if reviewer.notifications.none?

Rails.logger.info("Seeded review account #{email}")
