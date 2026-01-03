# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::FlukebaseConnect::BatchOperations", type: :request do
  let(:user) { create(:user) }
  let(:raw_token) { "fbk_#{SecureRandom.urlsafe_base64(32)}" }
  let!(:api_token) do
    create(:api_token,
           user:,
           raw_token:,
           scopes: %w[read:projects read:context read:environment read:memories])
  end
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  # Create multiple projects for the user
  let!(:project1) { create(:project, user:, name: "Project Alpha") }
  let!(:project2) { create(:project, user:, name: "Project Beta") }
  let!(:project3) { create(:project, user:, name: "Project Gamma") }

  describe "GET /api/v1/flukebase_connect/batch/context" do
    context "with all=true" do
      it "returns context for all accessible projects" do
        get "/api/v1/flukebase_connect/batch/context",
            headers: auth_headers,
            params: { all: "true" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["contexts"].length).to eq(3)
        expect(json["meta"]["count"]).to eq(3)
        expect(json["meta"]["successful"]).to eq(3)
        expect(json["meta"]["failed"]).to eq(0)
      end

      it "includes project metadata in each context" do
        get "/api/v1/flukebase_connect/batch/context",
            headers: auth_headers,
            params: { all: "true" }

        json = JSON.parse(response.body)
        first_context = json["contexts"].first

        expect(first_context).to include("project_id", "project_name", "context")
        expect(first_context["context"]).to be_a(Hash)
      end
    end

    context "with project_ids array" do
      it "returns context for specified projects only" do
        get "/api/v1/flukebase_connect/batch/context",
            headers: auth_headers,
            params: { "project_ids" => [project1.id, project2.id] }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["contexts"].length).to eq(2)

        project_ids = json["contexts"].map { |c| c["project_id"] }
        expect(project_ids).to contain_exactly(project1.id, project2.id)
      end
    end

    context "with no parameters" do
      it "returns empty contexts array" do
        get "/api/v1/flukebase_connect/batch/context", headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["contexts"]).to eq([])
        expect(json["meta"]["count"]).to eq(0)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/flukebase_connect/batch/context", params: { all: "true" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/flukebase_connect/batch/environment" do
    before do
      # Create environment variables for projects
      create(:environment_variable, project: project1, key: "API_KEY", environment: "development")
      create(:environment_variable, project: project1, key: "SECRET", environment: "development")
      create(:environment_variable, project: project2, key: "DATABASE_URL", environment: "development")
    end

    context "with all=true" do
      it "returns environment for all accessible projects" do
        get "/api/v1/flukebase_connect/batch/environment",
            headers: auth_headers,
            params: { all: "true" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["environments"].length).to eq(3)
        expect(json["meta"]["environment"]).to eq("development")
        expect(json["meta"]["total_variables"]).to eq(3)
      end

      it "returns correct variable counts per project" do
        get "/api/v1/flukebase_connect/batch/environment",
            headers: auth_headers,
            params: { all: "true" }

        json = JSON.parse(response.body)
        project1_env = json["environments"].find { |e| e["project_id"] == project1.id }

        expect(project1_env["variables_count"]).to eq(2)
        expect(project1_env["variables"].length).to eq(2)
      end
    end

    context "with specific environment" do
      before do
        create(:environment_variable, project: project1, key: "PROD_KEY", environment: "production")
      end

      it "filters by environment" do
        get "/api/v1/flukebase_connect/batch/environment",
            headers: auth_headers,
            params: { all: "true", environment: "production" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["meta"]["environment"]).to eq("production")
        expect(json["meta"]["total_variables"]).to eq(1)
      end
    end

    context "with project_ids array" do
      it "returns environment for specified projects only" do
        get "/api/v1/flukebase_connect/batch/environment",
            headers: auth_headers,
            params: { "project_ids" => [project1.id] }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["environments"].length).to eq(1)
        expect(json["environments"].first["project_id"]).to eq(project1.id)
      end
    end
  end

  describe "GET /api/v1/flukebase_connect/batch/memories" do
    before do
      # Create memories for projects
      create(:project_memory, project: project1, user:, content: "Alpha fact", memory_type: "fact")
      create(:project_memory, project: project1, user:, content: "Alpha gotcha", memory_type: "gotcha")
      create(:project_memory, project: project2, user:, content: "Beta convention", memory_type: "convention")
      create(:project_memory, project: project3, user:, content: "Gamma decision", memory_type: "decision")
    end

    context "with all=true" do
      it "returns memories from all accessible projects" do
        get "/api/v1/flukebase_connect/batch/memories",
            headers: auth_headers,
            params: { all: "true" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["projects"].length).to eq(3)
        expect(json["meta"]["total_memories"]).to eq(4)
      end

      it "groups memories by project" do
        get "/api/v1/flukebase_connect/batch/memories",
            headers: auth_headers,
            params: { all: "true" }

        json = JSON.parse(response.body)
        project1_data = json["projects"].find { |p| p["project_id"] == project1.id }

        expect(project1_data["memories_count"]).to eq(2)
        expect(project1_data["project_name"]).to eq("Project Alpha")
      end
    end

    context "with type filter" do
      it "filters memories by type" do
        get "/api/v1/flukebase_connect/batch/memories",
            headers: auth_headers,
            params: { all: "true", type: "gotcha" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["meta"]["total_memories"]).to eq(1)
        expect(json["meta"]["type_filter"]).to eq("gotcha")
      end
    end

    context "with since filter" do
      before do
        # Create an old memory
        old_memory = create(:project_memory, project: project1, user:, content: "Old memory")
        old_memory.update_column(:updated_at, 1.week.ago)
      end

      it "filters memories by updated_at" do
        get "/api/v1/flukebase_connect/batch/memories",
            headers: auth_headers,
            params: { all: "true", since: 1.day.ago.iso8601 }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        # Should only include the 4 memories created in before block (not the old one)
        expect(json["meta"]["total_memories"]).to eq(4)
      end
    end

    context "with project_ids array" do
      it "returns memories for specified projects only" do
        get "/api/v1/flukebase_connect/batch/memories",
            headers: auth_headers,
            params: { "project_ids" => [project2.id, project3.id] }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["projects"].length).to eq(2)
        expect(json["meta"]["total_memories"]).to eq(2)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/flukebase_connect/batch/memories", params: { all: "true" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
