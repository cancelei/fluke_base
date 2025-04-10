class Message < ApplicationRecord
  # Associations
  belongs_to :conversation
  belongs_to :user

  # Validations
  validates :body, presence: true
  validates :conversation_id, presence: true
  validates :user_id, presence: true

  # Default values
  after_initialize :set_defaults, unless: :persisted?

  # Broadcast after creation
  after_create_commit -> {
    broadcast_append_to conversation,
      target: "conversation_#{conversation.id}_messages",
      partial: "messages/message",
      locals: { message: self, current_user: user }
  }

  # Add a timestamp to broadcast
  def broadcast_append_to(target, **options)
    super(target, **options.merge(locals: options.fetch(:locals, {}).merge(timestamp: Time.current)))
  end

  private

  def set_defaults
    self.read ||= false
  end
end
