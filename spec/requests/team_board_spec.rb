# frozen_string_literal: true

require "rails_helper"

RSpec.describe "TeamBoard", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  before do
    sign_in user
  end

  describe "GET /projects/:project_id/team_board" do
    context "with no tasks" do
      it "renders the board successfully" do
        get project_team_board_index_path(project)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Team Board")
        expect(response.body).to include("No pending tasks")
      end
    end

    context "with tasks in various statuses" do
      let!(:pending_task) { create(:wedo_task, :pending, project:) }
      let!(:in_progress_task) { create(:wedo_task, :in_progress, project:) }
      let!(:blocked_task) { create(:wedo_task, :blocked, project:) }
      let!(:completed_task) { create(:wedo_task, :completed, project:) }

      it "renders all tasks grouped by status" do
        get project_team_board_index_path(project)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(pending_task.task_id)
        expect(response.body).to include(in_progress_task.task_id)
        expect(response.body).to include(blocked_task.task_id)
        expect(response.body).to include(completed_task.task_id)
      end

      it "shows correct stats" do
        get project_team_board_index_path(project)

        # Stats bar should show counts
        expect(response.body).to include("4 tasks")
      end
    end

    context "with scope filter" do
      let!(:global_task) { create(:wedo_task, project:, scope: "global") }
      let!(:session_task) { create(:wedo_task, project:, scope: "session") }

      it "filters by global scope" do
        get project_team_board_index_path(project), params: { scope: "global" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(global_task.task_id)
        expect(response.body).not_to include(session_task.task_id)
      end

      it "filters by session scope" do
        get project_team_board_index_path(project), params: { scope: "session" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(session_task.task_id)
        expect(response.body).not_to include(global_task.task_id)
      end
    end

    context "with assignee filter" do
      let(:assignee) { create(:user) }
      let!(:assigned_task) { create(:wedo_task, project:, assignee:) }
      let!(:unassigned_task) { create(:wedo_task, project:) }

      it "filters by assignee" do
        get project_team_board_index_path(project), params: { assignee_id: assignee.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(assigned_task.task_id)
        expect(response.body).not_to include(unassigned_task.task_id)
      end
    end

    context "with subtasks" do
      let!(:parent_task) { create(:wedo_task, project:) }
      let!(:subtask) { create(:wedo_task, project:, parent_task:) }

      it "only shows root tasks in columns" do
        get project_team_board_index_path(project)

        expect(response).to have_http_status(:ok)
        # Parent task should be visible
        expect(response.body).to include(parent_task.task_id)
      end
    end

    context "with priority ordering" do
      let!(:low_task) { create(:wedo_task, :low_priority, project:) }
      let!(:urgent_task) { create(:wedo_task, :urgent, project:) }
      let!(:normal_task) { create(:wedo_task, project:) }

      it "orders tasks by priority" do
        get project_team_board_index_path(project)

        expect(response).to have_http_status(:ok)
        # Urgent task should appear first (check order in body)
        urgent_pos = response.body.index(urgent_task.task_id)
        low_pos = response.body.index(low_task.task_id)
        expect(urgent_pos).to be < low_pos
      end
    end
  end

  describe "GET /projects/:project_id/team_board/:id" do
    let!(:task) { create(:wedo_task, :with_tags, :with_synthesis_report, project:) }

    it "renders the task detail" do
      get project_team_board_path(project, task.task_id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(task.task_id)
      expect(response.body).to include(task.description)
    end

    context "with subtasks" do
      let!(:subtask) { create(:wedo_task, project:, parent_task: task) }

      it "shows subtask information" do
        get project_team_board_path(project, task.task_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Subtasks")
        expect(response.body).to include(subtask.task_id)
      end
    end

    context "when task not found" do
      it "returns 404 status" do
        get project_team_board_path(project, "NONEXISTENT")

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /projects/:project_id/team_board/:id" do
    let!(:task) { create(:wedo_task, :pending, project:) }

    it "updates task status" do
      patch project_team_board_path(project, task.task_id),
            params: { wedo_task: { status: "in_progress" } }

      expect(response).to redirect_to(project_team_board_index_path(project))
      expect(task.reload.status).to eq("in_progress")
    end

    it "updates task priority" do
      patch project_team_board_path(project, task.task_id),
            params: { wedo_task: { priority: "urgent" } }

      expect(task.reload.priority).to eq("urgent")
    end

    it "updates assignee" do
      assignee = create(:user)

      patch project_team_board_path(project, task.task_id),
            params: { wedo_task: { assignee_id: assignee.id } }

      expect(task.reload.assignee).to eq(assignee)
    end

    it "appends synthesis note" do
      patch project_team_board_path(project, task.task_id),
            params: {
              wedo_task: { status: "in_progress" },
              synthesis_note: "Moving to in progress"
            }

      expect(task.reload.synthesis_report).to include("Moving to in progress")
    end

    it "sets updated_by to current user" do
      patch project_team_board_path(project, task.task_id),
            params: { wedo_task: { status: "in_progress" } }

      expect(task.reload.updated_by).to eq(user)
    end

    context "as turbo_stream request" do
      it "responds successfully for status update" do
        patch project_team_board_path(project, task.task_id),
              params: { wedo_task: { status: "in_progress" } },
              as: :turbo_stream

        # Turbo stream update returns 204 No Content or 200 OK
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity for invalid status" do
        patch project_team_board_path(project, task.task_id),
              params: { wedo_task: { status: "invalid_status" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "access control" do
    let(:other_user) { create(:user) }
    let(:other_project) { create(:project, user: other_user) }

    it "denies access to another user's project" do
      get project_team_board_index_path(other_project)

      # Returns 404 (project not found) or redirects
      expect(response.status).to be_in([302, 404])
    end
  end

  describe "unauthenticated access" do
    before { sign_out user }

    it "redirects to login" do
      get project_team_board_index_path(project)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
