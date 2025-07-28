module UserMessaging
  extend ActiveSupport::Concern

  included do
    # Messaging relationships
    has_many :sent_conversations, class_name: "Conversation", foreign_key: "sender_id", dependent: :destroy
    has_many :received_conversations, class_name: "Conversation", foreign_key: "recipient_id", dependent: :destroy
    has_many :messages, dependent: :destroy

    # Notifications
    has_many :notifications, dependent: :destroy
  end

  def unread_notifications_count
    notifications.unread.count
  end

    def unread_conversations_count
    # Count conversations that have unread messages for this user
    Conversation.involving(self)
                .joins(:messages)
                .where.not(messages: { user_id: self.id })
                .where(messages: { read: false })
                .distinct
                .count
  end

  def all_conversations
    # Return all conversations involving this user, ordered by most recent message
    Conversation.involving(self)
                .includes(:sender, :recipient, messages: :user)
                .order_by_most_recent_message
  end
end
