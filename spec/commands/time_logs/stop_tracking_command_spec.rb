# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeLogs::StopTrackingCommand, type: :command do
  it_behaves_like "a time_log command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user:) }
    let(:milestone) { create(:milestone, project:, status: "in_progress") }

    context "with active time log" do
      let!(:time_log) do
        create(:time_log, :active, user:, project:, milestone:)
      end

      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s,
          milestoneId: milestone.id.to_s
        })
      end

      it "completes the time log" do
        command.execute
        time_log.reload
        expect(time_log.status).to eq("completed")
      end

      it "sets ended_at timestamp" do
        command.execute
        time_log.reload
        expect(time_log.ended_at).to be_present
      end

      it "clears the tracking state" do
        command.controller.session[:progress_milestone_id] = milestone.id
        command.execute
        expect(command.controller.session[:progress_milestone_id]).to be_nil
      end

      it "clears the current tracking container" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "current_tracking_container" }
        expect(stream).to be_present
      end

      it "updates the milestone row" do
        command.execute
        stream = command_streams(command).find { |s| s[:target]&.include?("milestone_") }
        expect(stream).to be_present
      end

      it "updates the pending confirmation section" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "pending_confirmation_section" }
        expect(stream).to be_present
      end

      it "displays a success message" do
        command.execute
        expect_flash_notice(command)
      end
    end

    context "without active time log" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s,
          milestoneId: milestone.id.to_s
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end

    context "with non-existent project" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: "999999",
          milestoneId: milestone.id.to_s
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end

    context "when another user is tracking" do
      let(:other_user) { create(:user) }
      let!(:other_time_log) do
        create(:time_log, :active, user: other_user, project:, milestone:)
      end

      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s,
          milestoneId: milestone.id.to_s
        })
      end

      it "displays an error message (cannot stop another user's log)" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end

      it "does not affect the other user's time log" do
        command.execute
        other_time_log.reload
        expect(other_time_log.status).to eq("in_progress")
      end
    end
  end
end
