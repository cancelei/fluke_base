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

ActiveRecord::Schema[8.0].define(version: 2025_12_24_031232) do
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

  create_table "admin_users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agreement_participants", force: :cascade do |t|
    t.bigint "agreement_id", null: false
    t.bigint "user_id", null: false
    t.string "user_role", null: false
    t.bigint "project_id", null: false
    t.boolean "is_initiator", default: false
    t.bigint "counter_agreement_id"
    t.bigint "accept_or_counter_turn_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accept_or_counter_turn_id"], name: "index_agreement_participants_on_accept_or_counter_turn_id"
    t.index ["agreement_id", "user_id"], name: "idx_agreement_participants_on_agreement_user", unique: true
    t.index ["counter_agreement_id"], name: "index_agreement_participants_on_counter_agreement_id"
    t.index ["is_initiator"], name: "idx_agreement_participants_on_is_initiator"
    t.index ["project_id"], name: "index_agreement_participants_on_project_id"
    t.index ["user_id"], name: "index_agreement_participants_on_user_id"
  end

  create_table "agreements", force: :cascade do |t|
    t.string "agreement_type", null: false
    t.string "status", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.bigint "project_id", null: false
    t.text "terms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_type", null: false
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "equity_percentage", precision: 5, scale: 2
    t.integer "weekly_hours"
    t.text "tasks", null: false
    t.integer "milestone_ids", default: [], array: true
    t.index ["agreement_type"], name: "index_agreements_on_agreement_type", comment: "Improves filtering by mentorship/co-founder type"
    t.index ["created_at"], name: "index_agreements_on_created_at", comment: "Improves ordering by creation date"
    t.index ["payment_type"], name: "index_agreements_on_payment_type"
    t.index ["project_id"], name: "index_agreements_on_project_id"
    t.index ["status", "agreement_type"], name: "index_agreements_on_status_and_agreement_type", comment: "Composite index for combined filtering"
    t.index ["status"], name: "index_agreements_on_status", comment: "Improves filtering by agreement status"
    t.check_constraint "agreement_type::text = ANY (ARRAY['Mentorship'::character varying::text, 'Co-Founder'::character varying::text])", name: "agreements_type_check"
    t.check_constraint "end_date >= start_date", name: "agreements_date_order_check"
    t.check_constraint "equity_percentage >= 0::numeric AND equity_percentage <= 100::numeric", name: "agreements_equity_percentage_check"
    t.check_constraint "hourly_rate >= 0::numeric", name: "agreements_hourly_rate_check"
    t.check_constraint "payment_type::text = ANY (ARRAY['Hourly'::character varying::text, 'Equity'::character varying::text, 'Hybrid'::character varying::text])", name: "agreements_payment_type_check"
    t.check_constraint "status::text = ANY (ARRAY['Pending'::character varying::text, 'Accepted'::character varying::text, 'Completed'::character varying::text, 'Rejected'::character varying::text, 'Cancelled'::character varying::text, 'Countered'::character varying::text])", name: "agreements_status_check"
    t.check_constraint "weekly_hours IS NULL OR weekly_hours > 0 AND weekly_hours <= 40", name: "agreements_weekly_hours_check"
  end

  create_table "contact_requests", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "company"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subject"
    t.boolean "newsletter"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "sender_id"], name: "index_conversations_on_recipient_and_sender", unique: true
    t.index ["sender_id"], name: "index_conversations_on_sender_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "github_branch_logs", force: :cascade do |t|
    t.bigint "github_branch_id", null: false
    t.bigint "github_log_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_branch_id", "github_log_id"], name: "index_github_branch_logs_on_github_branch_id_and_github_log_id", unique: true
    t.index ["github_log_id"], name: "index_github_branch_logs_on_github_log_id"
  end

  create_table "github_branches", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "user_id", null: false
    t.string "branch_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "branch_name", "user_id"], name: "idx_on_project_id_branch_name_user_id_fcdce7d2d8", unique: true
    t.index ["user_id"], name: "index_github_branches_on_user_id"
  end

  create_table "github_logs", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "agreement_id"
    t.bigint "user_id"
    t.string "commit_sha", null: false
    t.text "commit_message"
    t.integer "lines_added"
    t.integer "lines_removed"
    t.datetime "commit_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commit_url"
    t.jsonb "changed_files", default: [], array: true
    t.string "unregistered_user_name"
    t.index ["agreement_id"], name: "index_github_logs_on_agreement_id"
    t.index ["commit_date"], name: "index_github_logs_on_commit_date", comment: "Improves time-based queries for commit history"
    t.index ["commit_sha"], name: "index_github_logs_on_commit_sha", unique: true
    t.index ["project_id", "commit_date"], name: "index_github_logs_on_project_id_and_commit_date", comment: "Composite index for project commit timeline"
    t.index ["project_id"], name: "index_github_logs_on_project_id"
    t.index ["user_id", "commit_date"], name: "index_github_logs_on_user_id_and_commit_date", comment: "Composite index for user commit activity"
    t.index ["user_id"], name: "index_github_logs_on_user_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.bigint "agreement_id", null: false
    t.string "google_calendar_event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agreement_id", "start_time"], name: "index_meetings_on_agreement_id_and_start_time", comment: "Composite index for agreement meetings ordered by time"
    t.index ["agreement_id"], name: "index_meetings_on_agreement_id"
    t.index ["end_time"], name: "index_meetings_on_end_time", comment: "Improves past/upcoming meeting queries"
    t.index ["google_calendar_event_id"], name: "index_meetings_on_google_calendar_event_id"
    t.index ["start_time"], name: "index_meetings_on_start_time", comment: "Improves meeting ordering and time-based queries"
    t.check_constraint "end_time > start_time", name: "meetings_time_order_check"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "voice", default: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at", comment: "Composite index for conversation message history"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at", comment: "Improves message ordering in conversations"
    t.index ["read"], name: "index_messages_on_read", comment: "Improves unread message queries"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "milestone_enhancements", force: :cascade do |t|
    t.bigint "milestone_id", null: false
    t.bigint "user_id", null: false
    t.text "original_description"
    t.text "enhanced_description"
    t.json "context_data"
    t.integer "processing_time_ms"
    t.string "enhancement_style"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["milestone_id"], name: "index_milestone_enhancements_on_milestone_id"
    t.index ["user_id"], name: "index_milestone_enhancements_on_user_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.date "due_date", null: false
    t.string "status", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["due_date"], name: "index_milestones_on_due_date", comment: "Improves due date queries and sorting"
    t.index ["project_id", "due_date"], name: "index_milestones_on_project_id_and_due_date", comment: "Composite index for project milestone timeline"
    t.index ["project_id", "slug"], name: "index_milestones_on_project_id_and_slug", unique: true
    t.index ["project_id", "status"], name: "index_milestones_on_project_id_and_status", comment: "Composite index for project milestone progress"
    t.index ["project_id"], name: "index_milestones_on_project_id"
    t.index ["status"], name: "index_milestones_on_status", comment: "Improves filtering by milestone status"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'in_progress'::character varying::text, 'completed'::character varying::text, 'cancelled'::character varying::text])", name: "milestones_status_check"
  end

  create_table "newsletter_subscribers", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.datetime "subscribed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscribers_on_email", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.string "url"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at", comment: "Improves ordering notifications by recency"
    t.index ["read_at"], name: "index_notifications_on_read_at", comment: "Improves unread notifications queries"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at", comment: "Composite index for user's unread notifications"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pitch_versions", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.boolean "active"
    t.integer "version_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "project_agents", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "provider"
    t.string "model"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_agents_on_project_id"
  end

  create_table "project_memberships", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "invited_at"
    t.datetime "accepted_at"
    t.bigint "invited_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_project_memberships_on_invited_by_id"
    t.index ["project_id", "user_id"], name: "index_project_memberships_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_memberships_on_project_id"
    t.index ["user_id", "role"], name: "index_project_memberships_on_user_id_and_role"
    t.index ["user_id"], name: "index_project_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying::text, 'admin'::character varying::text, 'member'::character varying::text, 'guest'::character varying::text])", name: "project_memberships_role_check"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "stage", null: false
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
    t.string "repository_url"
    t.string "project_link"
    t.boolean "stealth_mode", default: false, null: false
    t.string "stealth_name"
    t.text "stealth_description"
    t.string "stealth_category"
    t.datetime "github_last_polled_at"
    t.string "slug"
    t.index ["collaboration_type"], name: "index_projects_on_collaboration_type", comment: "Improves filtering by seeking mentor/co-founder"
    t.index ["created_at"], name: "index_projects_on_created_at", comment: "Improves ordering by project creation"
    t.index ["github_last_polled_at"], name: "index_projects_on_github_last_polled_at"
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["stage"], name: "index_projects_on_stage", comment: "Improves filtering by project stage"
    t.index ["stealth_mode"], name: "index_projects_on_stealth_mode", comment: "Improves filtering of stealth vs public projects"
    t.index ["user_id"], name: "index_projects_on_user_id"
    t.check_constraint "stage::text = ANY (ARRAY['idea'::character varying::text, 'prototype'::character varying::text, 'launched'::character varying::text, 'scaling'::character varying::text])", name: "projects_stage_check"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "rater_id", null: false
    t.string "rateable_type", null: false
    t.bigint "rateable_id", null: false
    t.integer "value", null: false
    t.text "review"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rateable_type", "rateable_id"], name: "index_ratings_on_rateable"
    t.index ["rater_id", "rateable_type", "rateable_id"], name: "index_ratings_uniqueness", unique: true
    t.index ["rater_id"], name: "index_ratings_on_rater_id"
    t.check_constraint "value >= 1 AND value <= 5", name: "ratings_value_range"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", id: false, force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.text "command"
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "time_logs", force: :cascade do |t|
    t.bigint "milestone_id"
    t.datetime "started_at", precision: nil, null: false
    t.datetime "ended_at", precision: nil
    t.text "description"
    t.decimal "hours_spent", precision: 10, scale: 2, default: "0.0"
    t.string "status", default: "in_progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.boolean "manual_entry", default: false
    t.index ["milestone_id"], name: "index_time_logs_on_milestone_id"
    t.index ["project_id", "milestone_id"], name: "index_time_logs_on_project_id_and_milestone_id"
    t.index ["project_id", "user_id"], name: "index_time_logs_on_project_id_and_user_id", comment: "Composite index for user-project time logs"
    t.index ["started_at"], name: "index_time_logs_on_started_at", comment: "Improves time-based queries and reporting"
    t.index ["status"], name: "index_time_logs_on_status", comment: "Improves filtering by active/completed time logs"
    t.index ["user_id"], name: "index_time_logs_on_user_id"
    t.check_constraint "hours_spent >= 0::numeric", name: "time_logs_hours_check"
    t.check_constraint "status::text = ANY (ARRAY['in_progress'::character varying::text, 'completed'::character varying::text, 'paused'::character varying::text])", name: "time_logs_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "bio"
    t.string "avatar"
    t.bigint "selected_project_id"
    t.float "years_of_experience"
    t.float "hourly_rate"
    t.string "industries", default: [], array: true
    t.string "skills", default: [], array: true
    t.string "business_stage"
    t.string "help_seekings", default: [], array: true
    t.text "business_info"
    t.string "github_username"
    t.string "github_token", limit: 255
    t.boolean "show_project_context_nav", default: false, null: false
    t.string "linkedin"
    t.string "x"
    t.string "youtube"
    t.string "facebook"
    t.string "tiktok"
    t.boolean "multi_project_tracking", default: false, null: false
    t.string "theme_preference", default: "nord", null: false
    t.string "instagram"
    t.boolean "admin", default: false, null: false
    t.string "slug"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["selected_project_id"], name: "index_users_on_selected_project_id"
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "waiting_lists", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.string "company"
    t.string "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pitch_version_id"
    t.string "role"
    t.text "message"
    t.boolean "newsletter"
    t.index ["email"], name: "index_waiting_lists_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agreement_participants", "agreements"
  add_foreign_key "agreement_participants", "agreements", column: "counter_agreement_id"
  add_foreign_key "agreement_participants", "projects"
  add_foreign_key "agreement_participants", "users"
  add_foreign_key "agreement_participants", "users", column: "accept_or_counter_turn_id"
  add_foreign_key "agreements", "projects"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "github_branch_logs", "github_branches", on_delete: :cascade
  add_foreign_key "github_branch_logs", "github_logs", on_delete: :cascade
  add_foreign_key "github_branches", "projects"
  add_foreign_key "github_branches", "users"
  add_foreign_key "github_logs", "agreements"
  add_foreign_key "github_logs", "projects"
  add_foreign_key "github_logs", "users"
  add_foreign_key "meetings", "agreements"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "milestone_enhancements", "milestones"
  add_foreign_key "milestone_enhancements", "users"
  add_foreign_key "milestones", "projects"
  add_foreign_key "notifications", "users"
  add_foreign_key "project_agents", "projects"
  add_foreign_key "project_memberships", "projects"
  add_foreign_key "project_memberships", "users"
  add_foreign_key "project_memberships", "users", column: "invited_by_id"
  add_foreign_key "projects", "users"
  add_foreign_key "ratings", "users", column: "rater_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_processes", column: "process_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_processes", "solid_queue_processes", column: "supervisor_id", on_delete: :nullify
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "time_logs", "milestones"
  add_foreign_key "time_logs", "projects"
  add_foreign_key "time_logs", "users"
  add_foreign_key "users", "projects", column: "selected_project_id", on_delete: :nullify

  create_view "dashboard_stats", materialized: true, sql_definition: <<-SQL
      SELECT u.id AS user_id,
      u.email,
      COALESCE(p_stats.total_projects, (0)::bigint) AS total_projects,
      COALESCE(p_stats.projects_seeking_mentor, (0)::bigint) AS projects_seeking_mentor,
      COALESCE(p_stats.projects_seeking_cofounder, (0)::bigint) AS projects_seeking_cofounder,
      COALESCE(a_stats.total_agreements, (0)::bigint) AS total_agreements,
      COALESCE(a_stats.active_agreements, (0)::bigint) AS active_agreements,
      COALESCE(a_stats.completed_agreements, (0)::bigint) AS completed_agreements,
      COALESCE(a_stats.pending_agreements, (0)::bigint) AS pending_agreements,
      COALESCE(a_stats.agreements_as_initiator, (0)::bigint) AS agreements_as_initiator,
      COALESCE(a_stats.agreements_as_participant, (0)::bigint) AS agreements_as_participant,
      COALESCE(m_stats.total_meetings, (0)::bigint) AS total_meetings,
      COALESCE(m_stats.upcoming_meetings, (0)::bigint) AS upcoming_meetings,
      COALESCE(mil_stats.total_milestones, (0)::bigint) AS total_milestones,
      COALESCE(mil_stats.completed_milestones, (0)::bigint) AS completed_milestones,
      COALESCE(mil_stats.in_progress_milestones, (0)::bigint) AS in_progress_milestones,
      now() AS calculated_at
     FROM ((((users u
       LEFT JOIN ( SELECT projects.user_id,
              count(*) AS total_projects,
              count(
                  CASE
                      WHEN ((projects.collaboration_type)::text = ANY (ARRAY[('mentor'::character varying)::text, ('both'::character varying)::text])) THEN 1
                      ELSE NULL::integer
                  END) AS projects_seeking_mentor,
              count(
                  CASE
                      WHEN ((projects.collaboration_type)::text = ANY (ARRAY[('co-founder'::character varying)::text, ('both'::character varying)::text])) THEN 1
                      ELSE NULL::integer
                  END) AS projects_seeking_cofounder
             FROM projects
            GROUP BY projects.user_id) p_stats ON ((p_stats.user_id = u.id)))
       LEFT JOIN ( SELECT ap.user_id,
              count(*) AS total_agreements,
              count(
                  CASE
                      WHEN ((a.status)::text = 'Accepted'::text) THEN 1
                      ELSE NULL::integer
                  END) AS active_agreements,
              count(
                  CASE
                      WHEN ((a.status)::text = 'Completed'::text) THEN 1
                      ELSE NULL::integer
                  END) AS completed_agreements,
              count(
                  CASE
                      WHEN ((a.status)::text = 'Pending'::text) THEN 1
                      ELSE NULL::integer
                  END) AS pending_agreements,
              count(
                  CASE
                      WHEN (ap.is_initiator = true) THEN 1
                      ELSE NULL::integer
                  END) AS agreements_as_initiator,
              count(
                  CASE
                      WHEN (ap.is_initiator = false) THEN 1
                      ELSE NULL::integer
                  END) AS agreements_as_participant
             FROM (agreement_participants ap
               JOIN agreements a ON ((a.id = ap.agreement_id)))
            GROUP BY ap.user_id) a_stats ON ((a_stats.user_id = u.id)))
       LEFT JOIN ( SELECT ap.user_id,
              count(m.*) AS total_meetings,
              count(
                  CASE
                      WHEN (m.start_time > now()) THEN 1
                      ELSE NULL::integer
                  END) AS upcoming_meetings
             FROM ((agreement_participants ap
               JOIN agreements a ON ((a.id = ap.agreement_id)))
               LEFT JOIN meetings m ON ((m.agreement_id = a.id)))
            GROUP BY ap.user_id) m_stats ON ((m_stats.user_id = u.id)))
       LEFT JOIN ( SELECT p.user_id,
              count(mil.*) AS total_milestones,
              count(
                  CASE
                      WHEN ((mil.status)::text = 'completed'::text) THEN 1
                      ELSE NULL::integer
                  END) AS completed_milestones,
              count(
                  CASE
                      WHEN ((mil.status)::text = 'in_progress'::text) THEN 1
                      ELSE NULL::integer
                  END) AS in_progress_milestones
             FROM (projects p
               LEFT JOIN milestones mil ON ((mil.project_id = p.id)))
            GROUP BY p.user_id) mil_stats ON ((mil_stats.user_id = u.id)));
  SQL
  add_index "dashboard_stats", ["user_id"], name: "index_dashboard_stats_on_user_id", unique: true

end
