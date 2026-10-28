class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :title, null: false
      t.text :description
      t.string :priority, null: false, default: "medium"
      t.string :status, null: false, default: "todo"
      t.datetime :due_at
      t.datetime :reminder_at
      t.datetime :completed_at

      t.timestamps
    end
    add_index :tasks, %i[user_id status]
  end
end
