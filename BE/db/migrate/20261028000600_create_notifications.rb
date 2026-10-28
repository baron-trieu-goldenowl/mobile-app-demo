class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :title, null: false
      t.text :body
      t.boolean :read, null: false, default: false

      t.timestamps
    end
    add_index :notifications, %i[user_id created_at]
  end
end
