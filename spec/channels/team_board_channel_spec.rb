# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamBoardChannel, type: :channel do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "with valid project access" do
      it "subscribes to the project stream" do
        subscribe(project_id: project.id)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(project)
      end

      it "transmits connection confirmation" do
        subscribe(project_id: project.id)

        expect(transmissions.last).to include(
          "type" => "connected",
          "project_id" => project.id
        )
        expect(transmissions.last).to have_key("max_version")
        expect(transmissions.last).to have_key("timestamp")
      end
    end

    context "without project access" do
      let(:other_user) { create(:user) }
      let(:other_project) { create(:project, user: other_user) }

      it "rejects the subscription" do
        subscribe(project_id: other_project.id)

        expect(subscription).to be_rejected
      end
    end

    context "with invalid project_id" do
      it "rejects the subscription for nil project_id" do
        subscribe(project_id: nil)

        expect(subscription).to be_rejected
      end

      it "rejects the subscription for non-existent project" do
        subscribe(project_id: 999999)

        expect(subscription).to be_rejected
      end
    end
  end

  describe "#create_task" do
    before do
      subscribe(project_id: project.id)
    end

    it "creates a new task" do
      expect {
        perform :create_task, {
          "task_id" => "WS-001",
          "description" => "Task from WebSocket"
        }
      }.to change(WedoTask, :count).by(1)

      task = WedoTask.last
      expect(task.task_id).to eq("WS-001")
      expect(task.description).to eq("Task from WebSocket")
      expect(task.created_by).to eq(user)
    end

    it "transmits acknowledgment on success" do
      perform :create_task, {
        "task_id" => "WS-002",
        "description" => "Test task"
      }

      expect(transmissions.last).to include(
        "type" => "task.created.ack",
        "task_id" => "WS-002"
      )
      expect(transmissions.last).to have_key("version")
    end

    it "uses default values for optional fields" do
      perform :create_task, {
        "task_id" => "WS-003",
        "description" => "Minimal task"
      }

      task = WedoTask.last
      expect(task.status).to eq("pending")
      expect(task.dependency).to eq("AGENT_CAPABLE")
      expect(task.scope).to eq("global")
      expect(task.priority).to eq("normal")
    end

    it "transmits error on failure" do
      perform :create_task, {
        "task_id" => nil, # Invalid: missing task_id
        "description" => "Invalid task"
      }

      expect(transmissions.last).to include("type" => "error")
      expect(transmissions.last["action"]).to eq("create_task")
    end

    it "appends synthesis note with agent_id" do
      perform :create_task, {
        "task_id" => "WS-004",
        "description" => "Task with agent",
        "agent_id" => "test-agent-123"
      }

      task = WedoTask.last
      expect(task.synthesis_report).to include("test-agent-123")
    end
  end

  describe "#update_task" do
    let!(:task) { create(:wedo_task, project:, version: 1) }

    before do
      subscribe(project_id: project.id)
    end

    it "updates an existing task" do
      perform :update_task, {
        "task_id" => task.task_id,
        "status" => "in_progress"
      }

      expect(task.reload.status).to eq("in_progress")
    end

    it "transmits acknowledgment on success" do
      perform :update_task, {
        "task_id" => task.task_id,
        "status" => "completed"
      }

      expect(transmissions.last).to include(
        "type" => "task.updated.ack",
        "task_id" => task.task_id
      )
    end

    it "sets updated_by" do
      perform :update_task, {
        "task_id" => task.task_id,
        "priority" => "urgent"
      }

      expect(task.reload.updated_by).to eq(user)
    end

    it "appends synthesis note" do
      perform :update_task, {
        "task_id" => task.task_id,
        "synthesis_note" => "Updated via WebSocket",
        "agent_id" => "ws-agent"
      }

      expect(task.reload.synthesis_report).to include("Updated via WebSocket")
      expect(task.synthesis_report).to include("ws-agent")
    end

    it "handles array fields" do
      perform :update_task, {
        "task_id" => task.task_id,
        "tags" => %w[updated test],
        "blocked_by" => ["OTHER-001"]
      }

      task.reload
      expect(task.tags).to eq(%w[updated test])
      expect(task.blocked_by).to eq(["OTHER-001"])
    end

    context "optimistic locking" do
      it "transmits conflict when version is stale" do
        task.update!(description: "Updated elsewhere") # Increments version

        perform :update_task, {
          "task_id" => task.task_id,
          "status" => "in_progress",
          "version" => 1
        }

        expect(transmissions.last).to include("type" => "conflict")
        expect(transmissions.last["server_version"]).to be > 1
        expect(transmissions.last).to have_key("server_task")
      end

      it "allows update without version" do
        task.update!(description: "Updated elsewhere")

        perform :update_task, {
          "task_id" => task.task_id,
          "status" => "in_progress"
        }

        expect(transmissions.last["type"]).to eq("task.updated.ack")
      end
    end

    it "transmits error for non-existent task" do
      perform :update_task, {
        "task_id" => "NONEXISTENT",
        "status" => "in_progress"
      }

      expect(transmissions.last).to include("type" => "error")
      expect(transmissions.last["message"]).to include("not found")
    end
  end

  describe "#sync_request" do
    let!(:task1) { create(:wedo_task, project:, version: 5) }
    let!(:task2) { create(:wedo_task, project:, version: 10) }

    before do
      subscribe(project_id: project.id)
    end

    it "returns all tasks without since_version" do
      perform :sync_request, {}

      response = transmissions.last
      expect(response["type"]).to eq("sync.response")
      expect(response["tasks"].length).to eq(2)
      expect(response["max_version"]).to eq(10)
    end

    it "returns tasks since specified version" do
      perform :sync_request, { "since_version" => 6 }

      response = transmissions.last
      expect(response["tasks"].length).to eq(1)
      expect(response["tasks"].first["version"]).to be > 6
    end

    it "includes timestamp" do
      perform :sync_request, {}

      expect(transmissions.last).to have_key("timestamp")
    end
  end

  describe "#ping" do
    before do
      subscribe(project_id: project.id)
    end

    it "responds with pong" do
      perform :ping, {}

      expect(transmissions.last).to include("type" => "pong")
      expect(transmissions.last).to have_key("timestamp")
    end
  end

  describe "class methods" do
    describe ".broadcast_task_event" do
      let!(:task) { create(:wedo_task, project:) }

      it "broadcasts to project subscribers" do
        expect {
          TeamBoardChannel.broadcast_task_event(project, "task.created", task)
        }.to have_broadcasted_to(project).with(
          hash_including(
            type: "task.created",
            task: hash_including(task_id: task.task_id)
          )
        )
      end
    end

    describe ".broadcast_to_project" do
      it "broadcasts custom message with timestamp" do
        expect {
          TeamBoardChannel.broadcast_to_project(project, { type: "custom", data: "test" })
        }.to have_broadcasted_to(project).with(
          hash_including(type: "custom", data: "test")
        )
      end
    end
  end

  describe "model callback broadcasts" do
    before do
      subscribe(project_id: project.id)
    end

    it "broadcasts when task is created" do
      expect {
        create(:wedo_task, project:)
      }.to have_broadcasted_to(project).with(
        hash_including(type: "task.created")
      )
    end

    it "broadcasts when task is updated" do
      task = create(:wedo_task, project:)

      expect {
        task.update!(description: "Updated")
      }.to have_broadcasted_to(project).with(
        hash_including(type: "task.updated")
      )
    end

    it "broadcasts status change event" do
      task = create(:wedo_task, :pending, project:)

      expect {
        task.update!(status: "in_progress")
      }.to have_broadcasted_to(project).with(
        hash_including(type: "task.status_changed")
      )
    end
  end
end
