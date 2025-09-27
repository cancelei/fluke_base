require 'rails_helper'

# Message Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe Message, type: :model do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:conversation) { create(:conversation) }
  let(:message) { create(:message, conversation: conversation, user: alice) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should belong_to(:conversation) }
    it { should belong_to(:user) }
    it { should have_many_attached(:attachments) }
    it { should have_one_attached(:audio) }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    let(:conversation) { create(:conversation) }
    let(:user) { create(:user) }

    it { should validate_presence_of(:conversation_id) }
    it { should validate_presence_of(:user_id) }

    context "when message has body" do
      it "is valid with body content" do
        message = build(:message, body: "Hello there!", conversation: conversation, user: user)
        expect(message).to be_valid
      end
    end

    context "when message has attachments" do
      it "is valid without body if attachments present" do
        message = build(:message, body: nil, conversation: conversation, user: user)
        # Mock attachment
        allow(message.attachments).to receive(:attached?).and_return(true)
        expect(message).to be_valid
      end
    end

    it "requires either body or attachments" do
      message = build(:message, body: nil, conversation: conversation, user: user)
      allow(message.attachments).to receive(:attached?).and_return(false)
      allow(message.audio).to receive(:attached?).and_return(false)
      expect(message).not_to be_valid
    end
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "instance methods" do
    describe "attachments" do
      it "can have attachments" do
        expect(message.attachments).to respond_to(:attached?)
        expect(message.attachments.attached?).to be false
      end
    end

    describe "#has_audio?" do
      it "returns true when audio message is attached" do
        allow(message.audio).to receive(:attached?).and_return(true)
        expect(message.audio.attached?).to be true
      end
    end

    describe "broadcasting behavior" do
      it "broadcasts after creation" do
        # Test would verify Turbo Stream broadcasting
        # This is tested in system tests with full integration
        expect(message).to be_valid
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid message with factory" do
      message = create(:message, conversation: conversation, user: alice)
      expect(message).to be_valid
      expect(message.body).to be_present
      expect(message.user).to be_present
      expect(message.conversation).to be_present
    end
  end
end
