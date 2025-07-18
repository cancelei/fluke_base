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
end
