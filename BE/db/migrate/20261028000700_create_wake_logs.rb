class CreateWakeLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :wake_logs do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :alarm, foreign_key: { on_delete: :nullify }
      t.string :alarm_title
      t.datetime :scheduled_at
      t.datetime :dismissed_at, null: false
      t.integer :snooze_count, null: false, default: 0
      t.string :challenge_type
      t.integer :mission_seconds

      t.timestamps
    end
    add_index :wake_logs, %i[user_id dismissed_at]
  end
end
