# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeLogs::StartTrackingCommand, type: :command do
  it_behaves_like "a time_log command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user:) }
    let(:milestone) { create(:milestone, project:, status: "pending") }

    context "with valid project and milestone" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s,
          milestoneId: milestone.id.to_s
        })
      end

      it "creates a new in-progress time log" do
        expect { command.execute }.to change(TimeLog, :count).by(1)
        expect(TimeLog.last.status).to eq("in_progress")
      end

      it "sets the time log user" do
        command.execute
        expect(TimeLog.last.user).to eq(user)
      end

      it "sets the time log milestone" do
        command.execute
        expect(TimeLog.last.milestone).to eq(milestone)
      end

      it "updates milestone status to in_progress" do
        command.execute
        milestone.reload
        expect(milestone.status).to eq("in_progress")
      end

      it "updates the tracking state" do
        command.execute
        # With multi_project_tracking disabled, uses :progress_milestone_id
        expect(command.controller.session[:progress_milestone_id]).to eq(milestone.id)
      end

      it "updates the milestone row frame" do
        command.execute
        stream = command_streams(command).find { |s| s[:target]&.include?("milestone_") }
        expect(stream).to be_present
      end

      it "updates the current tracking container" do
        command.execute
        stream = command_streams(command).find { |s| s[:target] == "current_tracking_container" }
        expect(stream).to be_present
      end

      it "displays a success message" do
        command.execute
        expect_flash_notice(command)
      end
    end

    context "when already tracking" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s,
          milestoneId: milestone.id.to_s
        })
      end

      before do
        create(:time_log, :active, user:, project:, milestone:)
      end

      it "displays an error message" do
        command.execute
        expect_flash_error(command)
      end

      it "does not create a new time log" do
        expect { command.execute }.not_to change(TimeLog, :count)
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

    context "with non-existent milestone" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s,
          milestoneId: "999999"
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end

    context "when user doesn't own the project" do
      let(:other_user) { create(:user) }
      let(:command) do
        build_command(described_class, user: other_user, element_data: {
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
  end
end
