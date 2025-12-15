# frozen_string_literal: true

require "rails_helper"

RSpec.describe Milestones::RevertEnhancementCommand, type: :command do
  it_behaves_like "a milestone command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }
    let(:milestone) { create(:milestone, project: project, description: "Enhanced description") }

    context "with valid enhancement" do
      let(:enhancement) do
        create(:milestone_enhancement,
               milestone: milestone,
               user: user,
               original_description: "Original description",
               enhanced_description: "Enhanced description",
               status: "completed")
      end

      let(:command) do
        build_command(described_class, user: user, element_data: {
          enhancementId: enhancement.id.to_s
        })
      end

      it "reverts the milestone description to original" do
        command.execute
        milestone.reload
        expect(milestone.description).to eq("Original description")
      end

      it "clears the ai-suggestion-container" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "ai-suggestion-container" }
        expect(stream).to be_present
      end

      it "displays a success message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:notice]).to include("Reverted")
      end
    end

    context "with missing enhancement ID" do
      let(:command) do
        build_command(described_class, user: user, element_data: {})
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end

    context "with non-existent enhancement" do
      let(:command) do
        build_command(described_class, user: user, element_data: {
          enhancementId: "999999"
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end
  end
end
