class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    respond_to do |format|
      if @message.save
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
