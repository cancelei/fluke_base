# frozen_string_literal: true

# Auto-Gotcha Detection: Stores suggested gotchas from pattern analysis
# These are generated automatically from AI session error patterns and
# require human review before becoming actual ProjectMemories.
class CreateSuggestedGotchas < ActiveRecord::Migration[8.0]
  def change
    create_table :suggested_gotchas do |t|
      t.references :project, null: false, foreign_key: true

      # Trigger information
      t.string :trigger_type, null: false
      # Options: recurring_error, high_failure, retry_sequence, long_debugging, repeated_searches
      t.jsonb :trigger_data, default: {}
      # Contains: fingerprint, count, tool_name, error_message, error_category, sample_messages

      # LLM-generated suggestion
      t.text :suggested_content
      t.string :suggested_title

      # Review workflow
      t.string :status, default: "pending", null: false
      # Options: pending, approved, dismissed, edited
      t.references :approved_memory, foreign_key: { to_table: :project_memories }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at

      # Analysis metadata
      t.datetime :analyzed_at
      t.string :source_fingerprint
      # Unique fingerprint to prevent duplicate suggestions

      t.timestamps
    end

    add_index :suggested_gotchas, :status
    add_index :suggested_gotchas, :trigger_type
    add_index :suggested_gotchas, :source_fingerprint
    add_index :suggested_gotchas, [:project_id, :status]
    add_index :suggested_gotchas, [:project_id, :source_fingerprint],
              unique: true,
              name: "index_suggested_gotchas_unique_fingerprint"
  end
end
