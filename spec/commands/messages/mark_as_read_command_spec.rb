# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messages::MarkAsReadCommand, type: :command do
  it_behaves_like "a message command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    context "with valid conversation" do
      let(:conversation) { create(:conversation, sender: user, recipient: other_user) }

      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: conversation.id.to_s
        })
      end

      before do
        # Stub the conversation model methods
        allow(Conversation).to receive(:involving).and_return(Conversation.where(id: conversation.id))
        allow_any_instance_of(Conversation).to receive(:mark_as_read_for).with(user).and_return(true)
        allow(user).to receive(:unread_conversations_count).and_return(0)
      end

      it "marks the conversation as read" do
        expect_any_instance_of(Conversation).to receive(:mark_as_read_for).with(user)
        command.execute
      end

      context "when no more unread conversations" do
        before do
          allow(user).to receive(:unread_conversations_count).and_return(0)
        end

        it "clears the unread badge" do
          command.execute
          stream = command_streams(command).find { |s| s[:target] == "unread_messages_badge" }
          expect(stream).to be_present
        end
      end

      context "when there are still unread conversations" do
        before do
          allow(user).to receive(:unread_conversations_count).and_return(5)
        end

        it "updates the unread badge with new count" do
          command.execute
          stream = command_streams(command).find { |s| s[:target] == "unread_messages_badge" }
          expect(stream).to be_present
          expect(stream[:locals][:count]).to eq(5)
        end
      end
    end

    context "without conversation ID" do
      let(:command) do
        build_command(described_class, user: user, element_data: {})
      end

      it "returns silently without error" do
        expect { command.execute }.not_to raise_error
      end

      it "does not update any frames" do
        command.execute
        expect(command_streams(command)).to be_empty
      end
    end

    context "with non-existent conversation" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: "999999"
        })
      end

      before do
        # Stub to raise RecordNotFound
        allow(Conversation).to receive(:involving).and_return(Conversation.none)
        allow(Conversation.none).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "fails silently (logs warning)" do
        expect(Rails.logger).to receive(:warn).with(/not found/)
        command.execute
      end

      it "does not display an error to user" do
        allow(Rails.logger).to receive(:warn)
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_nil
      end
    end

    context "when user doesn't have access to conversation" do
      let(:conversation) { create(:conversation, sender: other_user, recipient: create(:user)) }

      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: conversation.id.to_s
        })
      end

      before do
        allow(Conversation).to receive(:involving).with(user).and_return(Conversation.none)
        allow(Conversation.none).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "fails silently" do
        allow(Rails.logger).to receive(:warn)
        expect { command.execute }.not_to raise_error
      end
    end
  end
end
