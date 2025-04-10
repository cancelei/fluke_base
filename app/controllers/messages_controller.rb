class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    respond_to do |format|
      if @message.save
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
    params.require(:message).permit(:body)
  end
end
