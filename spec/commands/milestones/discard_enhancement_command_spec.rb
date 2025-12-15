# frozen_string_literal: true

require "rails_helper"

RSpec.describe Milestones::DiscardEnhancementCommand, type: :command do
  it_behaves_like "a milestone command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:command) { build_command(described_class, user: user, element_data: {}) }

    it "clears the ai-suggestion-container frame" do
      command.execute

      stream = command_streams(command).find { |s| s[:target] == "ai-suggestion-container" }
      expect(stream).to be_present
      expect(stream[:action]).to eq(:update)
    end

    it "clears page state for polling" do
      # Set up initial state
      command.state.page["polling_active"] = true
      command.state.page["enhancement_id"] = 123

      command.execute

      # State should be cleared (delete returns nil for missing keys)
      expect(command.state.page["polling_active"]).to be_nil
      expect(command.state.page["enhancement_id"]).to be_nil
    end
  end
end
