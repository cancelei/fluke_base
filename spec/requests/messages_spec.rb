require 'rails_helper'

# TODO: Rewrite this test - messages are nested under conversations
RSpec.describe "Messages", type: :request do
  describe "POST /conversations/:conversation_id/messages" do
    it "creates a message and redirects" do
      sender = create(:user)
      recipient = create(:user)
      sign_in sender
      conversation = Conversation.between(sender.id, recipient.id)

      post conversation_messages_path(conversation), params: { message: { body: "Hello" } }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(conversation_path(conversation))
      expect(conversation.messages.last.body).to eq("Hello")
    end
  end
end
