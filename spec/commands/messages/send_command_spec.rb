# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messages::SendCommand, type: :command do
  it_behaves_like "a message command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:conversation) { create(:conversation, sender: user, recipient: other_user) }

    context "with valid message" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: conversation.id.to_s
        }, params: {
          body: "Hello, how are you?"
        })
      end

      before do
        # Stub conversation lookup - use and_call_original to allow real lookup
        allow(Conversation).to receive(:involving).and_call_original
        allow(Conversation).to receive(:involving).with(user).and_return(Conversation.where(id: conversation.id))

        # Stub the broadcast to avoid ActionCable in tests
        allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_return(true)

        # Stub the Message model callbacks to avoid broadcast complications
        allow_any_instance_of(Message).to receive(:broadcast_replace_to).and_return(true)
        allow_any_instance_of(Message).to receive(:broadcast_append_to).and_return(true)
      end

      it "creates a new message" do
        expect { command.execute }.to change(Message, :count).by(1)
      end

      it "sets the message body" do
        command.execute
        expect(Message.last.body).to eq("Hello, how are you?")
      end

      it "sets the message user" do
        command.execute
        expect(Message.last.user).to eq(user)
      end

      it "sets the message conversation" do
        command.execute
        expect(Message.last.conversation).to eq(conversation)
      end

      it "broadcasts the message to other participants" do
        command.execute
        expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).at_least(:once)
      end

      it "clears the message form" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "message_form" }
        expect(stream).to be_present
      end

      it "appends message to the container" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "messages_container" }
        expect(stream).to be_present
      end
    end

    context "with empty body" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: conversation.id.to_s
        }, params: {
          body: ""
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("empty")
      end

      it "does not create a message" do
        expect { command.execute }.not_to change(Message, :count)
      end
    end

    context "with blank body" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: conversation.id.to_s
        }, params: {
          body: "   "
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("empty")
      end
    end

    context "with nested message params" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: conversation.id.to_s
        }, params: {
          message: {
            body: "Nested message body"
          }
        })
      end

      before do
        allow(Conversation).to receive(:involving).and_call_original
        allow(Conversation).to receive(:involving).with(user).and_return(Conversation.where(id: conversation.id))
        allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_return(true)
        allow_any_instance_of(Message).to receive(:broadcast_replace_to).and_return(true)
        allow_any_instance_of(Message).to receive(:broadcast_append_to).and_return(true)
      end

      it "creates message from nested params" do
        expect { command.execute }.to change(Message, :count).by(1)
        expect(Message.last.body).to eq("Nested message body")
      end
    end

    context "with non-existent conversation" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: "999999"
        }, params: {
          body: "Hello"
        })
      end

      before do
        allow(Conversation).to receive(:involving).with(user).and_return(Conversation.none)
        allow(Conversation.none).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end

    context "when user doesn't have access to conversation" do
      let(:other_conversation) { create(:conversation, sender: other_user, recipient: create(:user)) }

      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: other_conversation.id.to_s
        }, params: {
          body: "Hello"
        })
      end

      before do
        allow(Conversation).to receive(:involving).with(user).and_return(Conversation.none)
        allow(Conversation.none).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end

    context "when message save fails" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          conversationId: conversation.id.to_s
        }, params: {
          body: "Test message"
        })
      end

      before do
        allow(Conversation).to receive(:involving).with(user).and_return(Conversation.where(id: conversation.id))
        # Stub message to fail validation
        allow_any_instance_of(Message).to receive(:save).and_return(false)
        allow_any_instance_of(Message).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return("Body is invalid")
      end

      it "displays validation errors" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("invalid")
      end
    end
  end
end
