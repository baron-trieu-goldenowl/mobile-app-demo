class CreateAlarms < ActiveRecord::Migration[7.1]
  def change
    create_table :alarms do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.string :time, null: false, limit: 5
      t.integer :repeat_days, array: true, null: false, default: []
      t.boolean :enabled, null: false, default: true
      t.string :sound, null: false, default: "classic"
      t.integer :volume, null: false, default: 80
      t.boolean :gradual_volume, null: false, default: true
      t.boolean :vibration, null: false, default: true
      t.integer :snooze_minutes, null: false, default: 5
      t.integer :snooze_limit, null: false, default: 3
      t.boolean :wake_up_check, null: false, default: false
      t.string :challenge_type, null: false, default: "none"
      t.string :challenge_difficulty, null: false, default: "easy"
      t.string :qr_code

      t.timestamps
    end
  end
end
