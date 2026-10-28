# External sign-in accounts (Google, Apple) linked to a user.
class CreateIdentities < ActiveRecord::Migration[7.1]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.string :refresh_token

      t.timestamps
    end
    add_index :identities, %i[provider uid], unique: true
    add_index :identities, %i[user_id provider], unique: true
  end
end
