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

ActiveRecord::Schema[8.0].define(version: 2025_06_11_162809) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "agreements", force: :cascade do |t|
    t.string "agreement_type"
    t.string "status"
    t.date "start_date"
    t.date "end_date"
    t.bigint "project_id", null: false
    t.text "terms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_type"
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "equity_percentage", precision: 5, scale: 2
    t.integer "weekly_hours"
    t.text "tasks"
    t.integer "counter_to_id"
    t.integer "milestone_ids", default: [], array: true
    t.bigint "initiator_id"
    t.bigint "other_party_id"
    t.jsonb "initiator_meta", default: {"id"=>nil, "role"=>nil}, null: false
    t.jsonb "agreement_meta", default: [], array: true
    t.bigint "counter_offer_turn_id"
    t.index ["counter_offer_turn_id"], name: "index_agreements_on_counter_offer_turn_id"
    t.index ["counter_to_id"], name: "index_agreements_on_counter_to_id"
    t.index ["initiator_id"], name: "index_agreements_on_initiator_id"
    t.index ["other_party_id"], name: "index_agreements_on_other_party_id"
    t.index ["payment_type"], name: "index_agreements_on_payment_type"
    t.index ["project_id"], name: "index_agreements_on_project_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id"], name: "index_conversations_on_recipient_id"
    t.index ["sender_id"], name: "index_conversations_on_sender_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "start_time"
    t.datetime "end_time"
    t.bigint "agreement_id", null: false
    t.string "google_calendar_event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agreement_id"], name: "index_meetings_on_agreement_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "voice", default: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.date "due_date"
    t.string "status"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_milestones_on_project_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "message"
    t.string "url"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "stage"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.string "current_stage"
    t.text "target_market"
    t.string "funding_status"
    t.string "team_size"
    t.string "collaboration_type"
    t.string "public_fields", default: [], null: false, array: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "time_logs", force: :cascade do |t|
    t.bigint "agreement_id", null: false
    t.bigint "milestone_id", null: false
    t.datetime "started_at", precision: nil, null: false
    t.datetime "ended_at", precision: nil
    t.text "description"
    t.decimal "hours_spent", precision: 10, scale: 2, default: "0.0"
    t.string "status", default: "in_progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agreement_id", "milestone_id"], name: "index_time_logs_on_agreement_id_and_milestone_id"
    t.index ["agreement_id"], name: "index_time_logs_on_agreement_id"
    t.index ["milestone_id"], name: "index_time_logs_on_milestone_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "onboarded", default: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "onboarded", default: false
    t.text "bio"
    t.string "avatar"
    t.integer "selected_project_id"
    t.string "expertise", default: [], array: true
    t.string "industry"
    t.float "years_of_experience"
    t.float "hourly_rate"
    t.string "industries", default: [], array: true
    t.string "skills", default: [], array: true
    t.string "business_stage"
    t.string "help_seekings", default: [], array: true
    t.text "business_info"
    t.bigint "current_role_id"
    t.string "github_username"
    t.index ["current_role_id"], name: "index_users_on_current_role_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["expertise"], name: "index_users_on_expertise", using: :gin
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agreements", "projects"
  add_foreign_key "agreements", "users", column: "counter_offer_turn_id"
  add_foreign_key "agreements", "users", column: "initiator_id"
  add_foreign_key "agreements", "users", column: "other_party_id"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "meetings", "agreements"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "milestones", "projects"
  add_foreign_key "notifications", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "time_logs", "agreements"
  add_foreign_key "time_logs", "milestones"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "roles", column: "current_role_id"
end
