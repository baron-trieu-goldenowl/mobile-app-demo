class AddKindAndDataToNotifications < ActiveRecord::Migration[7.1]
  def change
    change_table :notifications, bulk: true do |t|
      t.string :kind, null: false, default: "general"
      t.jsonb :data, null: false, default: {}
    end
  end
end
