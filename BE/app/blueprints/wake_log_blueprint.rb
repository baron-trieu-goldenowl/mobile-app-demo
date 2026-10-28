class WakeLogBlueprint < Blueprinter::Base
  identifier :id

  fields :alarm_id, :alarm_title, :scheduled_at, :dismissed_at,
         :snooze_count, :challenge_type, :mission_seconds
end
