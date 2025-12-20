# frozen_string_literal: true

module Messages
  # Command to send a new message in a conversation
  # Creates the message and broadcasts to participants
  # @return [Dry::Monads::Result] Success(message) or Failure(error)
  #
  # Usage in view:
  #   <form data-turbo-command="Messages::SendCommand#execute"
  #         data-conversation-id="<%= conversation.id %>">
  #     <textarea name="body"></textarea>
  #     <button type="submit">Send</button>
  #   </form>
  class SendCommand < ApplicationCommand
    def execute
      conversation_id = element_data(:conversationId) || params[:conversation_id]
      body = params[:body] || params.dig(:message, :body)

      if body.blank?
        flash_error("Message cannot be empty.")
        return failure_result(:validation_error, "Message cannot be empty.")
      end

      conversation = Conversation.involving(current_user).find(conversation_id)

      message = conversation.messages.build(
        user: current_user,
        body:
      )

      if message.save
        # Broadcast to all conversation participants via ActionCable
        broadcast_message(conversation, message)

        # Clear the message form
        clear_frame("message_form")

        # Append the new message to the conversation
        append_to_frame(
          "messages_container",
          partial: "messages/message",
          locals: { message:, current_user: }
        )

        Success(message)
      else
        flash_error(message.errors.full_messages.to_sentence)
        failure_result(:save_failed, message.errors.full_messages.to_sentence, errors: message.errors)
      end
    rescue ActiveRecord::RecordNotFound
      flash_error("Conversation not found.")
      failure_result(:not_found, "Conversation not found.")
    end

    private

    def broadcast_message(conversation, message)
      [conversation.sender, conversation.recipient].each do |participant|
        next if participant == current_user

        Turbo::StreamsChannel.broadcast_append_to(
          participant,
          target: "messages_container",
          partial: "messages/message",
          locals: { message:, current_user: participant }
        )
      end
    end
  end
end
