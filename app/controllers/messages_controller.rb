class MessagesController < ApplicationController
  include ResultHandling

  before_action :authenticate_user!
  before_action :set_conversation

  def create
    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    respond_to do |format|
      if @message.save
        @conversation.reload
        # Broadcast the message to the other user
        if @conversation.sender != current_user
          Turbo::StreamsChannel.broadcast_append_to(
            @conversation.sender,
            target: "conversation_#{@conversation.id}_messages",
            partial: "messages/message",
            locals: { message: @message, current_user: @conversation.sender }
          )

          Turbo::StreamsChannel.broadcast_replace_to(
            @conversation.sender,
            target: "conversation_#{@conversation.id}_item",
            partial: "conversations/conversation_item",
            locals: { conversation: @conversation, current_conversation: nil, current_user: @conversation.sender }
          )

          # Update unread badge for the other user
          unread_count = @conversation.sender.unread_conversations_count
          Turbo::StreamsChannel.broadcast_update_to(
            @conversation.sender,
            target: "unread_messages_badge",
            partial: "shared/unread_messages_badge",
            locals: { count: unread_count }
          )
          Turbo::StreamsChannel.broadcast_update_to(
            @conversation.sender,
            target: "unread_messages_badge_mobile",
            partial: "shared/unread_messages_badge_mobile",
            locals: { count: unread_count }
          )
        end

        if @conversation.recipient != current_user
          Turbo::StreamsChannel.broadcast_append_to(
            @conversation.recipient,
            target: "conversation_#{@conversation.id}_messages",
            partial: "messages/message",
            locals: { message: @message, current_user: @conversation.recipient }
          )

          Turbo::StreamsChannel.broadcast_replace_to(
            @conversation.recipient,
            target: "conversation_#{@conversation.id}_item",
            partial: "conversations/conversation_item",
            locals: { conversation: @conversation, current_conversation: nil, current_user: @conversation.recipient }
          )

          # Update unread badge for the other user
          unread_count = @conversation.recipient.unread_conversations_count
          Turbo::StreamsChannel.broadcast_update_to(
            @conversation.recipient,
            target: "unread_messages_badge",
            partial: "shared/unread_messages_badge",
            locals: { count: unread_count }
          )
          Turbo::StreamsChannel.broadcast_update_to(
            @conversation.recipient,
            target: "unread_messages_badge_mobile",
            partial: "shared/unread_messages_badge_mobile",
            locals: { count: unread_count }
          )
        end

        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      else
        format.html { redirect_to conversation_path(@conversation), alert: "Failed to send message" }
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:body, :voice, :audio, attachments: [])
  end
end
