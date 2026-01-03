# frozen_string_literal: true

# Migration to create ai_conversation_logs table for storing AI provider chat exchanges.
# This enables the Unified Logs dashboard to display AI conversation history from
# flukebase_connect sessions (Claude and OpenAI providers).
class CreateAiConversationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_conversation_logs do |t|
      t.references :project, foreign_key: true, index: true
      t.references :user, foreign_key: true, index: true

      # Provider identification
      t.string :provider, null: false        # claude, openai
      t.string :model, null: false           # claude-3-opus, gpt-4, etc.

      # Session tracking
      t.string :session_id, null: false      # flukebase_connect session ID
      t.string :external_id                  # for sync deduplication
      t.integer :message_index, default: 0   # order within conversation

      # Message content
      t.string :role, null: false            # user, assistant, system
      t.text :content                        # the actual message content

      # Token metrics
      t.integer :input_tokens
      t.integer :output_tokens
      t.float :duration_ms

      # Extended metadata (tool_calls, function responses, etc.)
      t.jsonb :metadata, default: {}

      # When the exchange actually occurred (vs when synced)
      t.datetime :exchanged_at

      t.timestamps
    end

    # Composite index for efficient session lookups
    add_index :ai_conversation_logs, [:project_id, :session_id]

    # Unique index for sync deduplication
    add_index :ai_conversation_logs, :external_id, unique: true, where: "external_id IS NOT NULL"

    # Index for provider filtering
    add_index :ai_conversation_logs, :provider

    # Index for chronological queries
    add_index :ai_conversation_logs, :exchanged_at
  end
end
