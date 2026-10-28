class AlarmBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :time, :repeat_days, :enabled,
         :sound, :volume, :gradual_volume, :vibration,
         :snooze_minutes, :snooze_limit, :wake_up_check,
         :challenge_type, :challenge_difficulty, :qr_code
end
