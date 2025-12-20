# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeLogs::CreateManualCommand, type: :command do
  it_behaves_like "a time_log command"

  describe "#execute" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user:) }
    let(:milestone) { create(:milestone, project:, status: "pending") }

    context "with valid parameters" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s
        }, params: {
          milestone_id: milestone.id.to_s,
          time_log: {
            hours_spent: "2.5",
            description: "Manual development work",
            started_at: 3.hours.ago.iso8601,
            ended_at: 30.minutes.ago.iso8601
          }
        })
      end

      it "creates a completed time log" do
        expect { command.execute }.to change(TimeLog, :count).by(1)
        expect(TimeLog.last.status).to eq("completed")
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

      it "updates the milestone row" do
        command.execute
        stream = command_streams(command).find { |s| s[:target]&.include?("milestone_") }
        expect(stream).to be_present
      end

      it "displays a success message" do
        command.execute
        expect_flash_notice(command)
      end
    end

    context "without milestone selection" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s
        }, params: {
          time_log: {
            hours_spent: "2.5",
            description: "Manual work"
          }
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("select a milestone")
      end

      it "does not create a time log" do
        expect { command.execute }.not_to change(TimeLog, :count)
      end
    end

    context "with non-existent milestone" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s
        }, params: {
          milestone_id: "999999",
          time_log: {
            hours_spent: "2.5",
            description: "Manual work"
          }
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("Milestone not found")
      end
    end

    context "with non-existent project" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: "999999"
        }, params: {
          milestone_id: milestone.id.to_s,
          time_log: {
            hours_spent: "2.5"
          }
        })
      end

      it "displays an error message" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end

    context "with invalid time log params" do
      let(:command) do
        build_command(described_class, user:, element_data: {
          projectId: project.id.to_s
        }, params: {
          milestone_id: milestone.id.to_s,
          time_log: {
            hours_spent: "-5", # Invalid negative hours
            description: ""
          }
        })
      end

      it "displays validation errors" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        # Should show validation error from model
      end
    end

    context "when user doesn't own the project" do
      let(:other_user) { create(:user) }
      let(:command) do
        build_command(described_class, user: other_user, element_data: {
          projectId: project.id.to_s
        }, params: {
          milestone_id: milestone.id.to_s,
          time_log: { hours_spent: "2.5" }
        })
      end

      it "displays a project not found error" do
        command.execute
        flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
        expect(flash_stream).to be_present
        expect(flash_stream[:locals][:alert]).to include("not found")
      end
    end
  end
end
