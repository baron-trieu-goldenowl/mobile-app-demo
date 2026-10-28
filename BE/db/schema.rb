# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_10_28_000700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "alarms", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "time", limit: 5, null: false
    t.integer "repeat_days", default: [], null: false, array: true
    t.boolean "enabled", default: true, null: false
    t.string "sound", default: "classic", null: false
    t.integer "volume", default: 80, null: false
    t.boolean "gradual_volume", default: true, null: false
    t.boolean "vibration", default: true, null: false
    t.integer "snooze_minutes", default: 5, null: false
    t.integer "snooze_limit", default: 3, null: false
    t.boolean "wake_up_check", default: false, null: false
    t.string "challenge_type", default: "none", null: false
    t.string "challenge_difficulty", default: "easy", null: false
    t.string "qr_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_alarms_on_user_id"
  end

  create_table "calendar_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "location"
    t.datetime "start_at", null: false
    t.datetime "end_at"
    t.boolean "all_day", default: false, null: false
    t.string "source", default: "local", null: false
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "external_id"], name: "index_calendar_events_on_user_id_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["user_id", "start_at"], name: "index_calendar_events_on_user_id_and_start_at"
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.string "email"
    t.string "refresh_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_identities_on_user_id_and_provider", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "body"
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "priority", default: "medium", null: false
    t.string "status", default: "todo", null: false
    t.datetime "due_at"
    t.datetime "reminder_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_tasks_on_user_id_and_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.string "google_refresh_token"
    t.string "google_access_token"
    t.datetime "google_token_expires_at"
    t.datetime "google_calendar_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  create_table "wake_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "alarm_id"
    t.string "alarm_title"
    t.datetime "scheduled_at"
    t.datetime "dismissed_at", null: false
    t.integer "snooze_count", default: 0, null: false
    t.string "challenge_type"
    t.integer "mission_seconds"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alarm_id"], name: "index_wake_logs_on_alarm_id"
    t.index ["user_id", "dismissed_at"], name: "index_wake_logs_on_user_id_and_dismissed_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alarms", "users", on_delete: :cascade
  add_foreign_key "calendar_events", "users", on_delete: :cascade
  add_foreign_key "identities", "users", on_delete: :cascade
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "tasks", "users", on_delete: :cascade
  add_foreign_key "wake_logs", "alarms", on_delete: :nullify
  add_foreign_key "wake_logs", "users", on_delete: :cascade
end
