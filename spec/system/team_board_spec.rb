# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Team Board", type: :system, js: true do
  let(:user) { create(:user, first_name: "Alice", last_name: "Dev") }
  let(:project) { create(:project, user:, name: "Test Project") }

  before do
    sign_in user
  end

  describe "board display" do
    context "with no tasks" do
      it "displays empty board with all columns" do
        visit project_team_board_index_path(project)

        expect(page).to have_content("Team Board")
        expect(page).to have_content("Test Project")
        expect(page).to have_content("0 tasks")

        # All columns should be visible
        expect(page).to have_content("Pending")
        expect(page).to have_content("In Progress")
        expect(page).to have_content("Blocked")
        expect(page).to have_content("Completed")

        # Empty state messages
        expect(page).to have_content("No pending tasks")
      end
    end

    context "with tasks in various statuses" do
      let!(:pending_task) do
        create(:wedo_task, :pending, project:, task_id: "PEND-001",
               description: "Pending task description", created_by: user)
      end
      let!(:in_progress_task) do
        create(:wedo_task, :in_progress, project:, task_id: "PROG-001",
               description: "In progress task", created_by: user)
      end
      let!(:blocked_task) do
        create(:wedo_task, :blocked, project:, task_id: "BLCK-001",
               description: "Blocked task", created_by: user)
      end
      let!(:completed_task) do
        create(:wedo_task, :completed, project:, task_id: "DONE-001",
               description: "Completed task", created_by: user)
      end

      it "displays tasks in correct columns" do
        visit project_team_board_index_path(project)

        expect(page).to have_content("4 tasks")

        # Tasks should appear in their respective columns
        within("#column-pending") do
          expect(page).to have_content("PEND-001")
          expect(page).to have_content("Pending task description")
        end

        within("#column-in_progress") do
          expect(page).to have_content("PROG-001")
        end

        within("#column-blocked") do
          expect(page).to have_content("BLCK-001")
        end

        within("#column-completed") do
          expect(page).to have_content("DONE-001")
        end
      end

      it "shows correct stats in header" do
        visit project_team_board_index_path(project)

        # Stats bar should show 1 for each status
        expect(page).to have_css(".stat-value", text: "1", minimum: 4)
      end
    end

    context "with priority indicators" do
      let!(:urgent_task) do
        create(:wedo_task, :urgent, project:, task_id: "URG-001",
               description: "Urgent task", created_by: user)
      end

      it "displays priority badges" do
        visit project_team_board_index_path(project)

        within("#column-pending") do
          expect(page).to have_content("Urgent")
        end
      end
    end

    context "with tags" do
      let!(:tagged_task) do
        create(:wedo_task, project:, task_id: "TAG-001",
               description: "Tagged task", tags: %w[feature api],
               created_by: user)
      end

      it "displays task tags" do
        visit project_team_board_index_path(project)

        expect(page).to have_content("feature")
        expect(page).to have_content("api")
      end
    end
  end

  describe "task cards" do
    let!(:task) do
      create(:wedo_task, project:, task_id: "CARD-001",
             description: "Test card task", created_by: user)
    end

    it "cards have draggable attribute" do
      visit project_team_board_index_path(project)

      task_card = find("[data-task-id='CARD-001']")
      expect(task_card["draggable"]).to eq("true")
    end

    it "displays task metadata" do
      visit project_team_board_index_path(project)

      within("[data-task-id='CARD-001']") do
        expect(page).to have_content("CARD-001")
        expect(page).to have_content("Test card task")
        expect(page).to have_content("Unassigned")
      end
    end
  end

  describe "scope filtering" do
    let!(:global_task) do
      create(:wedo_task, project:, task_id: "GLOB-001", scope: "global", created_by: user)
    end
    let!(:session_task) do
      create(:wedo_task, project:, task_id: "SESS-001", scope: "session", created_by: user)
    end

    it "can filter by global scope via URL" do
      visit project_team_board_index_path(project, scope: "global")

      expect(page).to have_content("GLOB-001")
      expect(page).not_to have_content("SESS-001")
    end

    it "can filter by session scope via URL" do
      visit project_team_board_index_path(project, scope: "session")

      expect(page).not_to have_content("GLOB-001")
      expect(page).to have_content("SESS-001")
    end
  end

  describe "connection status" do
    let!(:task) { create(:wedo_task, project:, created_by: user) }

    it "shows connection status indicator" do
      visit project_team_board_index_path(project)

      expect(page).to have_css("[data-team-board-target='connectionStatus']")
    end
  end

  describe "task detail page" do
    let!(:task) do
      create(:wedo_task, project:, task_id: "DETAIL-001",
             description: "Task with full details",
             priority: "high",
             tags: %w[feature backend],
             created_by: user)
    end

    it "can view task details on show page" do
      visit project_team_board_path(project, task.task_id)

      expect(page).to have_content("DETAIL-001")
      expect(page).to have_content("Task with full details")
      expect(page).to have_content("High Priority")
    end
  end
end
