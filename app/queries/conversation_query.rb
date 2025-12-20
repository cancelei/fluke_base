class ConversationQuery
  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def empty_conversations
    conversation_ids = Conversation.involving(@current_user).select("conversations.id as conversation_id")
                 .joins("LEFT JOIN messages ON conversations.id = messages.conversation_id")
                                   .where("conversations.created_at < ?", 5.minute.ago).group("conversations.id")
                                   .having("COUNT(messages.id) = 0").map(&:conversation_id)
    Conversation.where(id: conversation_ids).destroy_all
  end
end
