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

ActiveRecord::Schema[8.1].define(version: 2026_01_03_100003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.string "username"
  end

  create_table "agent_sessions", force: :cascade do |t|
    t.string "agent_id", null: false
    t.string "agent_type", default: "claude_code"
    t.jsonb "capabilities", default: []
    t.string "client_version"
    t.datetime "connected_at"
    t.datetime "created_at", null: false
    t.datetime "disconnected_at"
    t.string "ip_address"
    t.datetime "last_heartbeat_at"
    t.jsonb "metadata", default: {}
    t.string "persona_name"
    t.bigint "project_id", null: false
    t.string "status", default: "active", null: false
    t.integer "tokens_used", default: 0
    t.integer "tools_executed", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["agent_id"], name: "index_agent_sessions_on_agent_id"
    t.index ["last_heartbeat_at"], name: "index_agent_sessions_on_last_heartbeat_at"
    t.index ["persona_name"], name: "index_agent_sessions_on_persona_name"
    t.index ["project_id", "agent_id"], name: "index_agent_sessions_on_project_id_and_agent_id", unique: true
    t.index ["project_id", "status"], name: "index_agent_sessions_on_project_id_and_status"
    t.index ["project_id"], name: "index_agent_sessions_on_project_id"
    t.index ["user_id"], name: "index_agent_sessions_on_user_id"
  end

  create_table "agreement_participants", force: :cascade do |t|
    t.bigint "accept_or_counter_turn_id"
    t.bigint "agreement_id", null: false
    t.bigint "counter_agreement_id"
    t.datetime "created_at", null: false
    t.boolean "is_initiator", default: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "user_role", null: false
    t.index ["accept_or_counter_turn_id"], name: "index_agreement_participants_on_accept_or_counter_turn_id"
    t.index ["agreement_id", "user_id"], name: "idx_agreement_participants_on_agreement_user", unique: true
    t.index ["counter_agreement_id"], name: "index_agreement_participants_on_counter_agreement_id"
    t.index ["is_initiator"], name: "idx_agreement_participants_on_is_initiator"
    t.index ["project_id"], name: "index_agreement_participants_on_project_id"
    t.index ["user_id"], name: "index_agreement_participants_on_user_id"
  end

  create_table "agreements", force: :cascade do |t|
    t.string "agreement_type", null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.decimal "equity_percentage", precision: 5, scale: 2
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.integer "milestone_ids", default: [], array: true
    t.string "payment_type", null: false
    t.bigint "project_id", null: false
    t.date "start_date", null: false
    t.string "status", null: false
    t.text "tasks", null: false
    t.text "terms"
    t.datetime "updated_at", null: false
    t.integer "weekly_hours"
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

  create_table "ai_conversation_logs", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.float "duration_ms"
    t.datetime "exchanged_at"
    t.string "external_id"
    t.integer "input_tokens"
    t.integer "message_index", default: 0
    t.jsonb "metadata", default: {}
    t.string "model", null: false
    t.integer "output_tokens"
    t.bigint "project_id"
    t.string "provider", null: false
    t.string "role", null: false
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["exchanged_at"], name: "index_ai_conversation_logs_on_exchanged_at"
    t.index ["external_id"], name: "index_ai_conversation_logs_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["project_id", "session_id"], name: "index_ai_conversation_logs_on_project_id_and_session_id"
    t.index ["project_id"], name: "index_ai_conversation_logs_on_project_id"
    t.index ["provider"], name: "index_ai_conversation_logs_on_provider"
    t.index ["user_id"], name: "index_ai_conversation_logs_on_user_id"
  end

  create_table "ai_productivity_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id"
    t.jsonb "metric_data", default: {}, null: false
    t.string "metric_type", null: false
    t.datetime "period_end", null: false
    t.datetime "period_start", null: false
    t.string "period_type", default: "session", null: false
    t.bigint "project_id", null: false
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["external_id"], name: "index_ai_productivity_metrics_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["metric_type"], name: "index_ai_productivity_metrics_on_metric_type"
    t.index ["period_type"], name: "index_ai_productivity_metrics_on_period_type"
    t.index ["project_id", "metric_type", "period_start"], name: "idx_on_project_id_metric_type_period_start_c4a679eb0b"
    t.index ["project_id"], name: "index_ai_productivity_metrics_on_project_id"
    t.index ["user_id"], name: "index_ai_productivity_metrics_on_user_id"
    t.check_constraint "metric_type::text = ANY (ARRAY['time_saved'::character varying::text, 'code_contribution'::character varying::text, 'task_velocity'::character varying::text, 'token_efficiency'::character varying::text])", name: "ai_productivity_metrics_metric_type_check"
    t.check_constraint "period_type::text = ANY (ARRAY['session'::character varying::text, 'daily'::character varying::text, 'weekly'::character varying::text, 'monthly'::character varying::text])", name: "ai_productivity_metrics_period_type_check"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "last_used_ip"
    t.string "name", null: false
    t.string "prefix", limit: 8, null: false
    t.datetime "revoked_at"
    t.text "scopes", default: [], array: true
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["prefix"], name: "index_api_tokens_on_prefix"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id", "revoked_at"], name: "index_api_tokens_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "browser_test_runs", force: :cascade do |t|
    t.json "assertions", default: []
    t.bigint "cloudflare_worker_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.bigint "project_id"
    t.json "results", default: {}
    t.text "screenshot_base64"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.string "suite_name"
    t.string "test_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["cloudflare_worker_id"], name: "index_browser_test_runs_on_cloudflare_worker_id"
    t.index ["created_at"], name: "index_browser_test_runs_on_created_at"
    t.index ["project_id"], name: "index_browser_test_runs_on_project_id"
    t.index ["status"], name: "index_browser_test_runs_on_status"
    t.index ["test_type"], name: "index_browser_test_runs_on_test_type"
    t.index ["user_id"], name: "index_browser_test_runs_on_user_id"
  end

  create_table "cloudflare_usage_metrics", force: :cascade do |t|
    t.integer "browser_sessions", default: 0
    t.bigint "cloudflare_worker_id", null: false
    t.datetime "created_at", null: false
    t.decimal "estimated_cost_usd", precision: 10, scale: 4
    t.integer "execution_time_ms", default: 0
    t.string "period_type", default: "daily", null: false
    t.json "raw_metrics", default: {}
    t.date "recorded_date", null: false
    t.integer "requests_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["cloudflare_worker_id", "recorded_date", "period_type"], name: "idx_cloudflare_usage_metrics_unique", unique: true
    t.index ["cloudflare_worker_id"], name: "index_cloudflare_usage_metrics_on_cloudflare_worker_id"
    t.index ["recorded_date"], name: "index_cloudflare_usage_metrics_on_recorded_date"
  end

  create_table "cloudflare_workers", force: :cascade do |t|
    t.string "account_id", null: false
    t.json "configuration", default: {}
    t.datetime "created_at", null: false
    t.string "environment", default: "development", null: false
    t.datetime "last_deployed_at"
    t.datetime "last_health_check_at"
    t.string "name", null: false
    t.string "script_hash"
    t.string "status", default: "unknown", null: false
    t.datetime "updated_at", null: false
    t.string "worker_url"
    t.index ["environment"], name: "index_cloudflare_workers_on_environment"
    t.index ["name"], name: "index_cloudflare_workers_on_name", unique: true
    t.index ["status"], name: "index_cloudflare_workers_on_status"
  end

  create_table "contact_requests", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message"
    t.string "name"
    t.boolean "newsletter"
    t.string "subject"
    t.datetime "updated_at", null: false
  end

  create_table "container_pools", force: :cascade do |t|
    t.boolean "auto_delegate_enabled", default: true, null: false
    t.jsonb "config", default: {}, null: false
    t.integer "context_threshold_percent", default: 80, null: false
    t.datetime "created_at", null: false
    t.datetime "last_activity_at"
    t.integer "max_pool_size", default: 3, null: false
    t.bigint "project_id", null: false
    t.boolean "skip_user_required", default: true, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "warm_pool_size", default: 1, null: false
    t.index ["project_id"], name: "index_container_pools_on_project_id", unique: true
    t.index ["status"], name: "index_container_pools_on_status"
  end

  create_table "container_sessions", force: :cascade do |t|
    t.bigint "agent_session_id"
    t.string "container_id"
    t.bigint "container_pool_id", null: false
    t.integer "context_max_tokens", default: 100000
    t.float "context_percent", default: 0.0
    t.integer "context_used_tokens", default: 0
    t.datetime "created_at", null: false
    t.string "current_task_id"
    t.bigint "handoff_from_id"
    t.text "handoff_summary"
    t.datetime "last_activity_at"
    t.datetime "last_context_check_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "session_id", null: false
    t.string "status", default: "starting", null: false
    t.integer "tasks_completed", default: 0
    t.datetime "updated_at", null: false
    t.index ["agent_session_id"], name: "index_container_sessions_on_agent_session_id"
    t.index ["container_pool_id", "status"], name: "index_container_sessions_on_container_pool_id_and_status"
    t.index ["container_pool_id"], name: "index_container_sessions_on_container_pool_id"
    t.index ["context_percent"], name: "index_container_sessions_on_context_percent"
    t.index ["handoff_from_id"], name: "index_container_sessions_on_handoff_from_id"
    t.index ["session_id"], name: "index_container_sessions_on_session_id", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "sender_id"], name: "index_conversations_on_recipient_and_sender", unique: true
    t.index ["sender_id"], name: "index_conversations_on_sender_id"
  end

  create_table "delegation_requests", force: :cascade do |t|
    t.datetime "claimed_at"
    t.datetime "completed_at"
    t.bigint "container_session_id"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "project_id", null: false
    t.string "requested_by_session"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "wedo_task_id", null: false
    t.index ["container_session_id"], name: "index_delegation_requests_on_container_session_id"
    t.index ["project_id", "status"], name: "index_delegation_requests_on_project_id_and_status"
    t.index ["project_id"], name: "index_delegation_requests_on_project_id"
    t.index ["wedo_task_id", "status"], name: "index_delegation_requests_on_wedo_task_id_and_status"
    t.index ["wedo_task_id"], name: "index_delegation_requests_on_wedo_task_id"
  end

  create_table "environment_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "environment", null: false
    t.datetime "last_synced_at"
    t.jsonb "metadata", default: {}
    t.bigint "project_id", null: false
    t.integer "sync_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["project_id", "environment"], name: "index_environment_configs_on_project_id_and_environment", unique: true
    t.index ["project_id"], name: "index_environment_configs_on_project_id"
  end

  create_table "environment_variables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.string "environment", default: "development", null: false
    t.text "example_value"
    t.boolean "is_required", default: false, null: false
    t.boolean "is_secret", default: false, null: false
    t.string "key", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.string "validation_regex"
    t.text "value_ciphertext"
    t.index ["created_by_id"], name: "index_environment_variables_on_created_by_id"
    t.index ["project_id", "environment", "key"], name: "idx_env_vars_project_env_key", unique: true
    t.index ["project_id", "environment"], name: "index_environment_variables_on_project_id_and_environment"
    t.index ["project_id"], name: "index_environment_variables_on_project_id"
    t.index ["updated_by_id"], name: "index_environment_variables_on_updated_by_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "github_app_installations", force: :cascade do |t|
    t.string "account_login"
    t.string "account_type"
    t.datetime "created_at", null: false
    t.string "installation_id", null: false
    t.datetime "installed_at"
    t.jsonb "permissions", default: {}
    t.jsonb "repository_selection", default: {}
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["installation_id"], name: "index_github_app_installations_on_installation_id", unique: true
    t.index ["user_id"], name: "index_github_app_installations_on_user_id"
  end

  create_table "github_branch_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "github_branch_id", null: false
    t.bigint "github_log_id", null: false
    t.datetime "updated_at", null: false
    t.index ["github_branch_id", "github_log_id"], name: "index_github_branch_logs_on_github_branch_id_and_github_log_id", unique: true
    t.index ["github_log_id"], name: "index_github_branch_logs_on_github_log_id"
  end

  create_table "github_branches", force: :cascade do |t|
    t.string "branch_name"
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id", "branch_name", "user_id"], name: "idx_on_project_id_branch_name_user_id_fcdce7d2d8", unique: true
    t.index ["user_id"], name: "index_github_branches_on_user_id"
  end

  create_table "github_logs", force: :cascade do |t|
    t.bigint "agreement_id"
    t.jsonb "changed_files", default: [], array: true
    t.datetime "commit_date", null: false
    t.text "commit_message"
    t.string "commit_sha", null: false
    t.string "commit_url"
    t.datetime "created_at", null: false
    t.integer "lines_added"
    t.integer "lines_removed"
    t.bigint "project_id", null: false
    t.string "unregistered_user_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["agreement_id"], name: "index_github_logs_on_agreement_id"
    t.index ["commit_date"], name: "index_github_logs_on_commit_date", comment: "Improves time-based queries for commit history"
    t.index ["commit_sha"], name: "index_github_logs_on_commit_sha", unique: true
    t.index ["project_id", "commit_date"], name: "index_github_logs_on_project_id_and_commit_date", comment: "Composite index for project commit timeline"
    t.index ["project_id"], name: "index_github_logs_on_project_id"
    t.index ["user_id", "commit_date"], name: "index_github_logs_on_user_id_and_commit_date", comment: "Composite index for user commit activity"
    t.index ["user_id"], name: "index_github_logs_on_user_id"
  end

  create_table "mcp_plugins", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "author"
    t.boolean "built_in", default: false
    t.jsonb "configuration_schema", default: {}
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "features", default: {}
    t.string "homepage"
    t.string "icon_name"
    t.string "maturity", null: false
    t.string "name", null: false
    t.string "plugin_type", null: false
    t.string "required_scopes", default: [], array: true
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["active"], name: "index_mcp_plugins_on_active"
    t.index ["maturity"], name: "index_mcp_plugins_on_maturity"
    t.index ["plugin_type"], name: "index_mcp_plugins_on_plugin_type"
    t.index ["slug"], name: "index_mcp_plugins_on_slug", unique: true
  end

  create_table "mcp_presets", force: :cascade do |t|
    t.jsonb "context_level", default: {}
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "enabled_plugins", default: []
    t.string "name", null: false
    t.string "slug", null: false
    t.boolean "system_preset", default: false
    t.string "target_role", null: false
    t.jsonb "token_scopes", default: []
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_mcp_presets_on_slug", unique: true
    t.index ["system_preset"], name: "index_mcp_presets_on_system_preset"
    t.index ["target_role"], name: "index_mcp_presets_on_target_role"
  end

  create_table "meetings", force: :cascade do |t|
    t.bigint "agreement_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_time", null: false
    t.string "google_calendar_event_id"
    t.datetime "start_time", null: false
    t.string "title", null: false
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
    t.datetime "created_at", null: false
    t.boolean "read"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "voice", default: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at", comment: "Composite index for conversation message history"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at", comment: "Improves message ordering in conversations"
    t.index ["read"], name: "index_messages_on_read", comment: "Improves unread message queries"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "milestone_enhancements", force: :cascade do |t|
    t.json "context_data"
    t.datetime "created_at", null: false
    t.text "enhanced_description"
    t.string "enhancement_style"
    t.bigint "milestone_id", null: false
    t.text "original_description"
    t.integer "processing_time_ms"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["milestone_id"], name: "index_milestone_enhancements_on_milestone_id"
    t.index ["user_id"], name: "index_milestone_enhancements_on_user_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date", null: false
    t.bigint "project_id", null: false
    t.string "slug"
    t.string "status", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_milestones_on_due_date", comment: "Improves due date queries and sorting"
    t.index ["project_id", "due_date"], name: "index_milestones_on_project_id_and_due_date", comment: "Composite index for project milestone timeline"
    t.index ["project_id", "slug"], name: "index_milestones_on_project_id_and_slug", unique: true
    t.index ["project_id", "status"], name: "index_milestones_on_project_id_and_status", comment: "Composite index for project milestone progress"
    t.index ["project_id"], name: "index_milestones_on_project_id"
    t.index ["status"], name: "index_milestones_on_status", comment: "Improves filtering by milestone status"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'in_progress'::character varying::text, 'completed'::character varying::text, 'cancelled'::character varying::text])", name: "milestones_status_check"
  end

  create_table "newsletter_subscribers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "subscribed_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscribers_on_email", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at", comment: "Improves ordering notifications by recency"
    t.index ["read_at"], name: "index_notifications_on_read_at", comment: "Improves unread notifications queries"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at", comment: "Composite index for user's unread notifications"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pitch_versions", force: :cascade do |t|
    t.boolean "active"
    t.text "content"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "version_number"
  end

  create_table "project_agents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "model"
    t.bigint "project_id", null: false
    t.string "provider"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_agents_on_project_id"
  end

  create_table "project_mcp_configurations", force: :cascade do |t|
    t.jsonb "context_options", default: {}
    t.datetime "created_at", null: false
    t.jsonb "enabled_plugins", default: []
    t.jsonb "plugin_settings", default: {}
    t.string "preset", default: "developer"
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_mcp_configurations_on_project_id", unique: true
  end

  create_table "project_memberships", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "invited_at"
    t.bigint "invited_by_id"
    t.bigint "project_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["invited_by_id"], name: "index_project_memberships_on_invited_by_id"
    t.index ["project_id", "user_id"], name: "index_project_memberships_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_memberships_on_project_id"
    t.index ["user_id", "role"], name: "index_project_memberships_on_user_id_and_role"
    t.index ["user_id"], name: "index_project_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying::text, 'admin'::character varying::text, 'member'::character varying::text, 'guest'::character varying::text])", name: "project_memberships_role_check"
  end

  create_table "project_memories", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "external_id"
    t.string "key"
    t.string "memory_type", default: "fact", null: false
    t.bigint "project_id", null: false
    t.text "rationale"
    t.jsonb "references", default: {}
    t.datetime "synced_at"
    t.jsonb "tags", default: []
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["external_id"], name: "index_project_memories_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["project_id", "key"], name: "index_project_memories_on_project_id_and_key", unique: true, where: "(key IS NOT NULL)"
    t.index ["project_id", "memory_type"], name: "index_project_memories_on_project_id_and_memory_type"
    t.index ["project_id"], name: "index_project_memories_on_project_id"
    t.index ["user_id"], name: "index_project_memories_on_user_id"
    t.check_constraint "memory_type::text = ANY (ARRAY['fact'::character varying::text, 'convention'::character varying::text, 'gotcha'::character varying::text, 'decision'::character varying::text])", name: "project_memories_memory_type_check"
  end

  create_table "projects", force: :cascade do |t|
    t.string "category"
    t.string "collaboration_type"
    t.datetime "created_at", null: false
    t.string "current_stage"
    t.text "description", null: false
    t.string "funding_status"
    t.datetime "github_last_polled_at"
    t.string "name", null: false
    t.string "project_link"
    t.string "public_fields", default: [], null: false, array: true
    t.string "repository_url"
    t.string "slug"
    t.string "stage", null: false
    t.string "stealth_category"
    t.text "stealth_description"
    t.boolean "stealth_mode", default: false, null: false
    t.string "stealth_name"
    t.text "target_market"
    t.string "team_size"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
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
    t.datetime "created_at", null: false
    t.bigint "rateable_id", null: false
    t.string "rateable_type", null: false
    t.bigint "rater_id", null: false
    t.text "review"
    t.datetime "updated_at", null: false
    t.integer "value", null: false
    t.index ["rateable_type", "rateable_id"], name: "index_ratings_on_rateable"
    t.index ["rater_id", "rateable_type", "rateable_id"], name: "index_ratings_uniqueness", unique: true
    t.index ["rater_id"], name: "index_ratings_on_rater_id"
    t.check_constraint "value >= 1 AND value <= 5", name: "ratings_value_range"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", id: false, force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.text "command"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "suggested_gotchas", force: :cascade do |t|
    t.datetime "analyzed_at"
    t.bigint "approved_memory_id"
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "source_fingerprint"
    t.string "status", default: "pending", null: false
    t.text "suggested_content"
    t.string "suggested_title"
    t.jsonb "trigger_data", default: {}
    t.string "trigger_type", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_memory_id"], name: "index_suggested_gotchas_on_approved_memory_id"
    t.index ["project_id", "source_fingerprint"], name: "index_suggested_gotchas_unique_fingerprint", unique: true
    t.index ["project_id", "status"], name: "index_suggested_gotchas_on_project_id_and_status"
    t.index ["project_id"], name: "index_suggested_gotchas_on_project_id"
    t.index ["reviewed_by_id"], name: "index_suggested_gotchas_on_reviewed_by_id"
    t.index ["source_fingerprint"], name: "index_suggested_gotchas_on_source_fingerprint"
    t.index ["status"], name: "index_suggested_gotchas_on_status"
    t.index ["trigger_type"], name: "index_suggested_gotchas_on_trigger_type"
  end

  create_table "time_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ended_at", precision: nil
    t.decimal "hours_spent", precision: 10, scale: 2, default: "0.0"
    t.boolean "manual_entry", default: false
    t.bigint "milestone_id"
    t.bigint "project_id", null: false
    t.datetime "started_at", precision: nil, null: false
    t.string "status", default: "in_progress"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["milestone_id"], name: "index_time_logs_on_milestone_id"
    t.index ["project_id", "milestone_id"], name: "index_time_logs_on_project_id_and_milestone_id"
    t.index ["project_id", "user_id"], name: "index_time_logs_on_project_id_and_user_id", comment: "Composite index for user-project time logs"
    t.index ["started_at"], name: "index_time_logs_on_started_at", comment: "Improves time-based queries and reporting"
    t.index ["status"], name: "index_time_logs_on_status", comment: "Improves filtering by active/completed time logs"
    t.index ["user_id"], name: "index_time_logs_on_user_id"
    t.check_constraint "hours_spent >= 0::numeric", name: "time_logs_hours_check"
    t.check_constraint "status::text = ANY (ARRAY['in_progress'::character varying::text, 'completed'::character varying::text, 'paused'::character varying::text])", name: "time_logs_status_check"
  end

  create_table "user_onboarding_progress", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "first_ai_session_at"
    t.datetime "first_task_completed_at"
    t.jsonb "insights_seen", default: [], null: false
    t.jsonb "milestones_completed", default: [], null: false
    t.datetime "onboarding_completed_at"
    t.integer "onboarding_stage", default: 0, null: false
    t.jsonb "preferences", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["onboarding_stage"], name: "index_user_onboarding_progress_on_onboarding_stage"
    t.index ["user_id"], name: "index_user_onboarding_progress_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "avatar"
    t.text "bio"
    t.text "business_info"
    t.string "business_stage"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "facebook"
    t.string "first_name", null: false
    t.datetime "github_connected_at"
    t.text "github_refresh_token"
    t.datetime "github_refresh_token_expires_at"
    t.text "github_token"
    t.datetime "github_token_expires_at"
    t.string "github_uid"
    t.text "github_user_access_token"
    t.string "github_username"
    t.string "help_seekings", default: [], array: true
    t.float "hourly_rate"
    t.string "industries", default: [], array: true
    t.string "instagram"
    t.string "last_name", null: false
    t.string "linkedin"
    t.boolean "multi_project_tracking", default: false, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.bigint "selected_project_id"
    t.boolean "show_project_context_nav", default: false, null: false
    t.string "skills", default: [], array: true
    t.string "slug"
    t.string "theme_preference", default: "nord", null: false
    t.string "tiktok"
    t.datetime "updated_at", null: false
    t.string "x"
    t.float "years_of_experience"
    t.string "youtube"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_uid"], name: "index_users_on_github_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["selected_project_id"], name: "index_users_on_selected_project_id"
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "waiting_lists", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message"
    t.string "name"
    t.boolean "newsletter"
    t.integer "pitch_version_id"
    t.string "position"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_waiting_lists_on_email", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.string "event_type", null: false
    t.string "idempotency_key", null: false
    t.datetime "next_retry_at"
    t.jsonb "payload", default: {}, null: false
    t.text "response_body"
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.bigint "webhook_subscription_id", null: false
    t.index ["idempotency_key"], name: "index_webhook_deliveries_on_idempotency_key", unique: true
    t.index ["next_retry_at"], name: "index_webhook_deliveries_on_next_retry_at", where: "(delivered_at IS NULL)"
    t.index ["webhook_subscription_id", "created_at"], name: "idx_on_webhook_subscription_id_created_at_199b16efdc"
    t.index ["webhook_subscription_id"], name: "index_webhook_deliveries_on_webhook_subscription_id"
  end

  create_table "webhook_subscriptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "api_token_id", null: false
    t.string "callback_url", null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "events", default: ["env.updated"], array: true
    t.integer "failure_count", default: 0, null: false
    t.datetime "last_failure_at", precision: nil
    t.datetime "last_success_at", precision: nil
    t.bigint "project_id", null: false
    t.string "secret"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["api_token_id"], name: "index_webhook_subscriptions_on_api_token_id"
    t.index ["project_id", "active"], name: "index_webhook_subscriptions_on_project_id_and_active"
  end

  create_table "wedo_tasks", force: :cascade do |t|
    t.string "artifact_path"
    t.bigint "assignee_id"
    t.jsonb "blocked_by", default: []
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "dependency", default: "AGENT_CAPABLE", null: false
    t.text "description", null: false
    t.date "due_date"
    t.string "external_id"
    t.bigint "parent_task_id"
    t.string "priority", default: "normal", null: false
    t.bigint "project_id", null: false
    t.string "remote_url"
    t.string "scope", default: "global", null: false
    t.string "status", default: "pending", null: false
    t.text "synthesis_report", default: ""
    t.jsonb "tags", default: []
    t.string "task_id", null: false
    t.string "template_id"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.integer "version", default: 0, null: false
    t.index ["assignee_id"], name: "index_wedo_tasks_on_assignee_id"
    t.index ["created_at"], name: "index_wedo_tasks_on_created_at"
    t.index ["created_by_id"], name: "index_wedo_tasks_on_created_by_id"
    t.index ["external_id"], name: "index_wedo_tasks_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["parent_task_id"], name: "index_wedo_tasks_on_parent_task_id"
    t.index ["project_id", "scope"], name: "index_wedo_tasks_on_project_id_and_scope"
    t.index ["project_id", "status"], name: "index_wedo_tasks_on_project_id_and_status"
    t.index ["project_id", "task_id"], name: "index_wedo_tasks_on_project_id_and_task_id", unique: true
    t.index ["project_id"], name: "index_wedo_tasks_on_project_id"
    t.index ["tags"], name: "index_wedo_tasks_on_tags", using: :gin
    t.index ["updated_by_id"], name: "index_wedo_tasks_on_updated_by_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_sessions", "projects"
  add_foreign_key "agent_sessions", "users"
  add_foreign_key "agreement_participants", "agreements"
  add_foreign_key "agreement_participants", "agreements", column: "counter_agreement_id"
  add_foreign_key "agreement_participants", "projects"
  add_foreign_key "agreement_participants", "users"
  add_foreign_key "agreement_participants", "users", column: "accept_or_counter_turn_id"
  add_foreign_key "agreements", "projects"
  add_foreign_key "ai_conversation_logs", "projects"
  add_foreign_key "ai_conversation_logs", "users"
  add_foreign_key "ai_productivity_metrics", "projects"
  add_foreign_key "ai_productivity_metrics", "users"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "browser_test_runs", "cloudflare_workers"
  add_foreign_key "browser_test_runs", "projects"
  add_foreign_key "browser_test_runs", "users"
  add_foreign_key "cloudflare_usage_metrics", "cloudflare_workers"
  add_foreign_key "container_pools", "projects"
  add_foreign_key "container_sessions", "agent_sessions"
  add_foreign_key "container_sessions", "container_pools"
  add_foreign_key "container_sessions", "container_sessions", column: "handoff_from_id"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "delegation_requests", "container_sessions"
  add_foreign_key "delegation_requests", "projects"
  add_foreign_key "delegation_requests", "wedo_tasks"
  add_foreign_key "environment_configs", "projects"
  add_foreign_key "environment_variables", "projects"
  add_foreign_key "environment_variables", "users", column: "created_by_id"
  add_foreign_key "environment_variables", "users", column: "updated_by_id"
  add_foreign_key "github_app_installations", "users"
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
  add_foreign_key "project_mcp_configurations", "projects"
  add_foreign_key "project_memberships", "projects"
  add_foreign_key "project_memberships", "users"
  add_foreign_key "project_memberships", "users", column: "invited_by_id"
  add_foreign_key "project_memories", "projects"
  add_foreign_key "project_memories", "users"
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
  add_foreign_key "suggested_gotchas", "project_memories", column: "approved_memory_id"
  add_foreign_key "suggested_gotchas", "projects"
  add_foreign_key "suggested_gotchas", "users", column: "reviewed_by_id"
  add_foreign_key "time_logs", "milestones"
  add_foreign_key "time_logs", "projects"
  add_foreign_key "time_logs", "users"
  add_foreign_key "user_onboarding_progress", "users"
  add_foreign_key "users", "projects", column: "selected_project_id", on_delete: :nullify
  add_foreign_key "webhook_deliveries", "webhook_subscriptions"
  add_foreign_key "webhook_subscriptions", "api_tokens", name: "webhook_subscriptions_api_token_id_fkey"
  add_foreign_key "webhook_subscriptions", "projects", name: "webhook_subscriptions_project_id_fkey"
  add_foreign_key "wedo_tasks", "projects"
  add_foreign_key "wedo_tasks", "users", column: "assignee_id"
  add_foreign_key "wedo_tasks", "users", column: "created_by_id"
  add_foreign_key "wedo_tasks", "users", column: "updated_by_id"
  add_foreign_key "wedo_tasks", "wedo_tasks", column: "parent_task_id"

  create_view "ai_productivity_stats", materialized: true, sql_definition: <<-SQL
      SELECT project_id,
      COALESCE(sum(((metric_data ->> 'time_saved_minutes'::text))::numeric), (0)::numeric) AS total_time_saved_minutes,
      COALESCE(sum(((metric_data ->> 'lines_added'::text))::integer), (0)::bigint) AS total_lines_added,
      COALESCE(sum(((metric_data ->> 'lines_removed'::text))::integer), (0)::bigint) AS total_lines_removed,
      COALESCE(sum(((metric_data ->> 'files_changed'::text))::integer), (0)::bigint) AS total_files_changed,
      COALESCE(sum(((metric_data ->> 'total_commits'::text))::integer), (0)::bigint) AS total_commits,
      COALESCE(avg(((metric_data ->> 'completion_rate'::text))::numeric), (0)::numeric) AS avg_task_completion_rate,
      COALESCE(sum(((metric_data ->> 'completed_count'::text))::integer), (0)::bigint) AS total_tasks_completed,
      COALESCE(sum(((metric_data ->> 'total_tokens'::text))::integer), (0)::bigint) AS total_tokens_used,
      COALESCE(sum(((metric_data ->> 'estimated_cost_usd'::text))::numeric), (0)::numeric) AS total_estimated_cost,
      count(DISTINCT date(period_start)) AS active_days,
      min(period_start) AS first_activity_at,
      max(period_end) AS last_activity_at,
      now() AS calculated_at
     FROM ai_productivity_metrics
    GROUP BY project_id;
  SQL
  add_index "ai_productivity_stats", ["project_id"], name: "idx_ai_productivity_stats_project", unique: true

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
