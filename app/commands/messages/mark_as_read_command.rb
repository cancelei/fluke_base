# frozen_string_literal: true

module Messages
  # Command to mark a conversation as read for the current user
  # Updates the unread badge in the navbar
  # @return [Dry::Monads::Result] Success(conversation) or Failure(error)
  #
  # Usage in view:
  #   <div data-turbo-command="Messages::MarkAsReadCommand#execute"
  #        data-conversation-id="<%= conversation.id %>"
  #        data-action="click->conversation#selectConversation">
  #     <%= conversation.subject %>
  #   </div>
  class MarkAsReadCommand < ApplicationCommand
    def execute
      conversation_id = element_id(:conversationId)

      if conversation_id.blank?
        return failure_result(:missing_id, "No conversation ID provided")
      end

      conversation = Conversation.involving(current_user).find(conversation_id)
      conversation.mark_as_read_for(current_user)

      # Update unread badge in navbar (both desktop and mobile)
      unread_count = current_user.unread_conversations_count

      # Update desktop navbar badge
      if unread_count.zero?
        clear_frame("unread_messages_badge")
      else
        update_frame(
          "unread_messages_badge",
          partial: "shared/unread_messages_badge",
          locals: { count: unread_count }
        )
      end

      # Update mobile drawer badge
      if unread_count.zero?
        clear_frame("unread_messages_badge_mobile")
      else
        update_frame(
          "unread_messages_badge_mobile",
          partial: "shared/unread_messages_badge_mobile",
          locals: { count: unread_count }
        )
      end

      Success(conversation)
    rescue ActiveRecord::RecordNotFound
      # Silent fail - conversation not found or user doesn't have access
      Rails.logger.warn("MarkAsReadCommand: Conversation #{conversation_id} not found for user #{current_user.id}")
      failure_result(:not_found, "Conversation not found")
    end
  end
end
