class CreateCommunicationSystem < ActiveRecord::Migration[8.0]
  def change
    # Only create tables if they don't already exist (for new setups)
    return if table_exists?(:conversations)

    # Conversations table
    create_table :conversations do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.timestamps null: false
    end

    # Conversation indexes
    add_index :conversations, :sender_id
    add_index :conversations, [:recipient_id, :sender_id], unique: true, name: "index_conversations_on_recipient_and_sender"

    # Messages table
    create_table :messages do |t|
      t.text :body
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :read
      t.boolean :voice, default: false
      t.timestamps null: false
    end

    # Message indexes
    add_index :messages, :conversation_id
    add_index :messages, :user_id
    add_index :messages, :read, comment: "Improves unread message queries"
    add_index :messages, :created_at, comment: "Improves message ordering in conversations"
    add_index :messages, [:conversation_id, :created_at], comment: "Composite index for conversation message history"

    # Notifications table
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :message, null: false
      t.string :url
      t.datetime :read_at
      t.timestamps null: false
    end

    # Notification indexes
    add_index :notifications, :user_id
    add_index :notifications, :read_at, comment: "Improves unread notifications queries"
    add_index :notifications, :created_at, comment: "Improves ordering notifications by recency"
    add_index :notifications, [:user_id, :read_at], comment: "Composite index for user's unread notifications"
  end
end
