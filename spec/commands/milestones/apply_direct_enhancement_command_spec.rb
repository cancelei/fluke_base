# frozen_string_literal: true

require "rails_helper"

RSpec.describe Milestones::ApplyDirectEnhancementCommand, type: :command do
  it_behaves_like "a turbo_boost command"
  it_behaves_like "a milestone command"

  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  describe "#execute" do
    context "with valid enhanced description" do
      let(:enhanced_description) { "Title: Enhanced Title\nDescription: This is an enhanced description." }
      let(:original_description) { "Original description" }
      let(:original_title) { "Original title" }

      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            enhanced_description:,
            original_title:,
            original_description:
          }
        )
      end

      it "updates the milestone title field" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_title" }
        expect(stream).to be_present
        expect(stream[:action]).to eq(:replace)
      end

      it "updates the milestone description field" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_description" }
        expect(stream).to be_present
        expect(stream[:action]).to eq(:replace)
      end

      it "clears the ai-suggestion-container" do
        command.execute
        expect_stream_action(command, :update, target: "ai-suggestion-container")
      end

      it "shows a success flash message" do
        command.execute
        expect_stream_action(command, :update, target: "flash_messages")
      end
    end

    context "with description only (no title marker)" do
      let(:enhanced_description) { "This is just an enhanced description without title." }

      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            enhanced_description:,
            original_description: "Original"
          }
        )
      end

      it "updates only the description field" do
        command.execute
        description_stream = command_streams(command).find { |s| s[:target] == "milestone_description" }
        title_stream = command_streams(command).find { |s| s[:target] == "milestone_title" }

        expect(description_stream).to be_present
        # Title should not be updated when no title pattern found
        expect(title_stream).to be_nil
      end
    end

    context "with blank enhanced description" do
      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            enhanced_description: "",
            original_description: "Original"
          }
        )
      end

      it "shows an error flash message" do
        command.execute
        expect_stream_action(command, :update, target: "flash_messages")
      end

      it "does not update form fields" do
        command.execute
        streams = command_streams(command)
        field_updates = streams.select { |s| %w[milestone_title milestone_description].include?(s[:target]) }
        expect(field_updates).to be_empty
      end
    end

    context "with nil enhanced description" do
      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            original_description: "Original"
          }
        )
      end

      it "shows an error flash message" do
        command.execute
        expect_stream_action(command, :update, target: "flash_messages")
      end
    end
  end

  describe "content parsing" do
    let(:command) do
      build_command(
        described_class,
        user:,
        element_data: {
          enhanced_description:,
          original_description: "Original"
        }
      )
    end

    context "with Title: and Description: markers" do
      let(:enhanced_description) do
        "Title: My Amazing Project\nDescription: A detailed description of the project goals and milestones."
      end

      it "parses the title correctly" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_title" }
        expect(stream).to be_present
        expect(stream[:content] || stream.to_s).to include("My Amazing Project")
      end

      it "parses the description correctly" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_description" }
        expect(stream).to be_present
        expect(stream[:content] || stream.to_s).to include("detailed description")
      end
    end

    context "with multiline description" do
      let(:enhanced_description) do
        <<~TEXT
          Title: Multi-line Test
          Description: This is a description
          that spans multiple lines
          and has various content.
        TEXT
      end

      it "preserves the multiline description" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_description" }
        expect(stream).to be_present
      end
    end
  end
end
