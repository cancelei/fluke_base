require 'rails_helper'

RSpec.describe "Conversations", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:conversation) { create(:conversation, sender: user, recipient: other_user) }

  before do
    post user_session_path, params: {
      user: { email: user.email, password: user.password }
    }
  end

  describe "GET /index" do
    it "returns http success" do
      get "/conversations"
      expect(response).to have_http_status(:success)
    end

    it "shows user's conversations" do
      conversation # Create conversation
      get "/conversations"
      expect(response.body).to include(other_user.full_name)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/conversations/#{conversation.id}"
      expect(response).to have_http_status(:success)
    end

    it "shows conversation messages" do
      message = create(:message, conversation:, user:, body: "Test message")
      get "/conversations/#{conversation.id}"
      expect(response.body).to include("Test message")
    end
  end
end
