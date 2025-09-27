require 'rails_helper'

# Conversation Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe Conversation, type: :model do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:conversation) { create(:conversation, sender: alice, recipient: bob) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should have_many(:messages).dependent(:destroy) }
    it { should belong_to(:sender).class_name("User") }
    it { should belong_to(:recipient).class_name("User") }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    subject { create(:conversation) }

    it "validates presence of sender and recipient" do
      conversation = build(:conversation, sender: nil, recipient: nil)
      expect(conversation).not_to be_valid
      expect(conversation.errors[:sender]).to include("must exist")
      expect(conversation.errors[:recipient]).to include("must exist")
    end

    it "validates uniqueness of sender and recipient combination" do
      existing = create(:conversation, sender: alice, recipient: bob)
      duplicate = build(:conversation, sender: alice, recipient: bob)

      expect(duplicate).not_to be_valid
    end
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "instance methods" do
    describe "#other_user" do
      it "returns the other user for given user" do
        expect(conversation.other_user(alice)).to eq(bob)
        expect(conversation.other_user(bob)).to eq(alice)
      end
    end

    describe "#last_message" do
      it "returns most recent message" do
        old_message = create(:message, conversation: conversation, user: alice, created_at: 1.hour.ago)
        new_message = create(:message, conversation: conversation, user: bob, created_at: 1.minute.ago)

        expect(conversation.last_message).to eq(new_message)
      end
    end

    describe "#unread_messages_for?" do
      it "returns true when user has unread messages" do
        create(:message, conversation: conversation, user: bob, read: false)
        expect(conversation.unread_messages_for?(alice)).to be true
      end

      it "returns false when user has no unread messages" do
        create(:message, conversation: conversation, user: bob, read: true)
        expect(conversation.unread_messages_for?(alice)).to be false
      end
    end

    describe "#mark_as_read_for" do
      it "marks all messages as read for user" do
        message1 = create(:message, conversation: conversation, user: bob, read: false)
        message2 = create(:message, conversation: conversation, user: bob, read: false)

        conversation.mark_as_read_for(alice)

        expect(message1.reload.read).to be true
        expect(message2.reload.read).to be true
      end
    end
  end

  # Scope Testing - Line 104-126 in test_spec
  describe "scopes" do
    let(:carol) { create(:user) }
    let!(:alice_bob_conv) { create(:conversation, sender: alice, recipient: bob) }
    let!(:alice_carol_conv) { create(:conversation, sender: alice, recipient: carol) }
    let!(:bob_carol_conv) { create(:conversation, sender: bob, recipient: carol) }

    describe ".involving" do
      it "returns conversations involving specific user" do
        alice_conversations = Conversation.involving(alice)
        expect(alice_conversations).to include(alice_bob_conv, alice_carol_conv)
        expect(alice_conversations).not_to include(bob_carol_conv)
      end
    end

    describe ".between" do
      it "finds conversation between two specific users" do
        result = Conversation.between(alice.id, bob.id)
        expect(result).to eq(alice_bob_conv)
      end

      it "finds conversation regardless of sender/recipient order" do
        result = Conversation.between(bob.id, alice.id)
        expect(result).to eq(alice_bob_conv)
      end
    end

    describe ".order_by_most_recent_message" do
      it "orders conversations by last message" do
        create(:message, conversation: alice_carol_conv, created_at: 1.minute.ago)
        create(:message, conversation: alice_bob_conv, created_at: 1.hour.ago)

        recent = Conversation.order_by_most_recent_message
        expect(recent.first).to eq(alice_carol_conv)
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid conversation with factory" do
      conversation = create(:conversation, sender: alice, recipient: bob)
      expect(conversation).to be_valid
      expect(conversation.sender).to eq(alice)
      expect(conversation.recipient).to eq(bob)
    end
  end
end
