class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :name
      t.string :password_digest
      t.string :google_refresh_token
      t.string :google_access_token
      t.datetime :google_token_expires_at
      t.datetime :google_calendar_synced_at

      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
