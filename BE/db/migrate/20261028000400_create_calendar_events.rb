class CreateCalendarEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :calendar_events do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :title, null: false
      t.text :description
      t.string :location
      t.datetime :start_at, null: false
      t.datetime :end_at
      t.boolean :all_day, null: false, default: false
      t.string :source, null: false, default: "local"
      t.string :external_id

      t.timestamps
    end
    add_index :calendar_events, %i[user_id start_at]
    add_index :calendar_events, %i[user_id external_id], unique: true, where: "external_id IS NOT NULL"
  end
end
