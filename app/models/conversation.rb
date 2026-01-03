# == Schema Information
#
# Table name: conversations
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  recipient_id :bigint           not null
#  sender_id    :bigint           not null
#
# Indexes
#
#  index_conversations_on_recipient_and_sender  (recipient_id,sender_id) UNIQUE
#  index_conversations_on_sender_id             (sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (recipient_id => users.id)
#  fk_rails_...  (sender_id => users.id)
#
class Conversation < ApplicationRecord
  # Associations
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :messages, -> { order(created_at: :asc) }, dependent: :destroy

  # Validations
  validates :sender_id, uniqueness: { scope: :recipient_id }

  # Scope for finding conversations involving a specific user
  scope :involving, ->(user) do
    where("sender_id = ? OR recipient_id = ?", user.id, user.id)
  end

  # Scope to order conversations by most recent message
  scope :order_by_most_recent_message, -> do
    joins("LEFT JOIN (SELECT conversation_id, MAX(created_at) as last_message_time FROM messages GROUP BY conversation_id) as latest_messages ON conversations.id = latest_messages.conversation_id")
      .order("latest_messages.last_message_time DESC NULLS LAST")
  end

  # Find or create a conversation between two users
  def self.between(sender_id, recipient_id)
    conversation = find_by(sender_id:, recipient_id:)
    if conversation.nil?
      conversation = find_by(sender_id: recipient_id, recipient_id: sender_id)
    end
    conversation = create(sender_id:, recipient_id:) if conversation.nil?
    conversation
  end

  # Return the other user in the conversation
  def other_user(current_user)
    current_user.id == sender_id ? recipient : sender
  end

  # Check if a conversation has unread messages for a user
  def unread_messages_for?(user)
    messages.where.not(user:).where(read: false).exists?
  end

  # Mark all unread messages as read for a user
  def mark_as_read_for(user)
    messages.where.not(user:).where(read: false).update_all(read: true)
  end

  # Get the last message of the conversation
  def last_message
    messages.order(created_at: :desc).first
  end
end
