class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [ :show ]

  def index
    @conversations = Conversation.involving(current_user).includes(:sender, :recipient, messages: :user)
    @conversation = @conversations.first if @conversations.any?
  end

  def show
    @conversations = Conversation.involving(current_user).includes(:sender, :recipient, messages: :user)
    @messages = @conversation.messages
    @message = Message.new

    # Mark messages as read
    @conversation.mark_as_read_for(current_user)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @conversation = Conversation.between(current_user.id, params[:recipient_id])
    redirect_to conversation_path(@conversation)
  end

  private

  def set_conversation
    @conversation = Conversation.involving(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to conversations_path, alert: "Conversation not found"
  end
end
