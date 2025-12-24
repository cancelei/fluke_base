# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  body            :text
#  read            :boolean
#  voice           :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_messages_on_conversation_id                 (conversation_id)
#  index_messages_on_conversation_id_and_created_at  (conversation_id,created_at)
#  index_messages_on_created_at                      (created_at)
#  index_messages_on_read                            (read)
#  index_messages_on_user_id                         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
class Message < ApplicationRecord
  # Class-level flag to skip broadcasts (useful for seeding)
  class_attribute :skip_broadcasts, default: false

  # Associations
  belongs_to :conversation
  belongs_to :user

  has_many_attached :attachments
  has_one_attached :audio # for voice messages

  # Validations
  validates :body, presence: true, unless: -> { audio.attached? || attachments.attached? }
  validates :conversation_id, presence: true
  validates :user_id, presence: true

  # Default values
  after_initialize :set_defaults, unless: :persisted?

  # Broadcast after creation (skipped when skip_broadcasts is true)
  after_create_commit -> {
    return if self.class.skip_broadcasts
    # Broadcast message to conversation
    broadcast_append_to conversation,
      target: "conversation_#{conversation.id}_messages",
      partial: "messages/message",
      locals: { message: self, current_user: user }

    # Broadcast update to both users' conversation lists
    [conversation.sender, conversation.recipient].each do |recipient_user|
      broadcast_replace_to recipient_user,
        target: "conversation_list",
        partial: "conversations/conversation_list",
        locals: {
          conversations: Conversation.involving(recipient_user)
                                   .includes(:sender, :recipient, messages: :user)
                                   .order_by_most_recent_message,
          current_conversation: conversation,
          current_user: recipient_user
        }
    end
  }

  # Add a timestamp to broadcast
  def broadcast_append_to(target, **options)
    super(target, **options.merge(locals: options.fetch(:locals, {}).merge(timestamp: Time.current)))
  end

  # Helper to run a block without broadcasts (useful for seeding)
  def self.without_broadcasts
    original = skip_broadcasts
    self.skip_broadcasts = true
    yield
  ensure
    self.skip_broadcasts = original
  end

  private

  def set_defaults
    self.read ||= false
  end
end
