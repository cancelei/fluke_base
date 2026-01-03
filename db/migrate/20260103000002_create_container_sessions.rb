# frozen_string_literal: true

class CreateContainerSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :container_sessions do |t|
      t.references :container_pool, null: false, foreign_key: true
      t.references :agent_session, foreign_key: true
      t.string :session_id, null: false
      t.string :container_id
      t.string :status, null: false, default: "starting"
      t.integer :context_used_tokens, default: 0
      t.integer :context_max_tokens, default: 100000
      t.float :context_percent, default: 0.0
      t.datetime :last_context_check_at
      t.datetime :last_activity_at
      t.string :current_task_id
      t.integer :tasks_completed, default: 0
      t.references :handoff_from, foreign_key: { to_table: :container_sessions }
      t.text :handoff_summary
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :container_sessions, :session_id, unique: true
    add_index :container_sessions, [:container_pool_id, :status]
    add_index :container_sessions, :context_percent
  end
end
