# frozen_string_literal: true

require "rails_helper"

RSpec.describe Milestones::RevertDirectEnhancementCommand, type: :command do
  it_behaves_like "a turbo_boost command"
  it_behaves_like "a milestone command"

  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  describe "#execute" do
    context "with valid original content" do
      let(:original_title) { "Original Title" }
      let(:original_description) { "Original description before enhancement" }

      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            original_title:,
            original_description:
          }
        )
      end

      it "updates the milestone title field with original value" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_title" }
        expect(stream).to be_present
        expect(stream[:action]).to eq(:replace)
        expect(stream[:content] || stream.to_s).to include(original_title)
      end

      it "updates the milestone description field with original value" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_description" }
        expect(stream).to be_present
        expect(stream[:action]).to eq(:replace)
        expect(stream[:content] || stream.to_s).to include(original_description)
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

    context "with description only (no title)" do
      let(:original_description) { "Original description only" }

      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            original_description:
          }
        )
      end

      it "updates only the description field" do
        command.execute
        description_stream = command_streams(command).find { |s| s[:target] == "milestone_description" }
        title_stream = command_streams(command).find { |s| s[:target] == "milestone_title" }

        expect(description_stream).to be_present
        expect(title_stream).to be_nil
      end

      it "shows a success flash message" do
        command.execute
        expect_stream_action(command, :update, target: "flash_messages")
      end
    end

    context "with blank original description" do
      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            original_title: "Title",
            original_description: ""
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

    context "with nil original description" do
      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            original_title: "Some Title"
          }
        )
      end

      it "shows an error flash message" do
        command.execute
        expect_stream_action(command, :update, target: "flash_messages")
      end
    end
  end

  describe "HTML escaping" do
    context "with special characters in content" do
      let(:original_title) { "Title with <script>alert('xss')</script>" }
      let(:original_description) { "Description with \"quotes\" and 'apostrophes' & ampersands" }

      let(:command) do
        build_command(
          described_class,
          user:,
          element_data: {
            original_title:,
            original_description:
          }
        )
      end

      it "escapes HTML in the title field" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_title" }
        expect(stream).to be_present
        # Content should be escaped
        content = stream[:content] || stream.to_s
        expect(content).not_to include("<script>")
        expect(content).to include("&lt;script&gt;") if content.include?("script")
      end

      it "escapes HTML in the description field" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "milestone_description" }
        expect(stream).to be_present
        content = stream[:content] || stream.to_s
        expect(content).to include("&amp;") if content.include?("ampersands")
      end
    end
  end
end
