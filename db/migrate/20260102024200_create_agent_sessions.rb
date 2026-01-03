# frozen_string_literal: true

class CreateAgentSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_sessions do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Agent identification
      t.string :agent_id, null: false
      t.string :persona_name
      t.string :agent_type, default: "claude_code"

      # Connection state
      t.string :status, default: "active", null: false
      t.datetime :last_heartbeat_at
      t.datetime :connected_at
      t.datetime :disconnected_at

      # Metadata
      t.jsonb :capabilities, default: []
      t.jsonb :metadata, default: {}
      t.string :ip_address
      t.string :client_version

      # Session metrics
      t.integer :tools_executed, default: 0
      t.integer :tokens_used, default: 0

      t.timestamps
    end

    add_index :agent_sessions, :agent_id
    add_index :agent_sessions, [:project_id, :agent_id], unique: true
    add_index :agent_sessions, [:project_id, :status]
    add_index :agent_sessions, :last_heartbeat_at
    add_index :agent_sessions, :persona_name
  end
end
