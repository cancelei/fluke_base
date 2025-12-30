# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::FlukebaseConnect::Memories", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:raw_token) { "fbk_#{SecureRandom.urlsafe_base64(32)}" }
  let!(:api_token) do
    create(:api_token,
           user: user,
           raw_token: raw_token,
           scopes: %w[read:projects read:memories write:memories])
  end
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  describe "GET /api/v1/flukebase_connect/projects/:project_id/memories" do
    let!(:memory1) { create(:project_memory, project: project, user: user, content: "First memory") }
    let!(:memory2) { create(:project_memory, project: project, user: user, content: "Second memory") }

    context "with valid authentication" do
      it "returns memories for the project" do
        get "/api/v1/flukebase_connect/projects/#{project.id}/memories", headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["memories"].length).to eq(2)
      end

      it "filters by type" do
        create(:project_memory, :gotcha, project: project, user: user)

        get "/api/v1/flukebase_connect/projects/#{project.id}/memories",
            headers: auth_headers,
            params: { type: "gotcha" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["memories"].length).to eq(1)
        expect(json["memories"].first["memory_type"]).to eq("gotcha")
      end

      it "includes pagination meta" do
        get "/api/v1/flukebase_connect/projects/#{project.id}/memories", headers: auth_headers

        json = JSON.parse(response.body)
        expect(json["meta"]).to include("total", "page", "per_page", "pages")
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/flukebase_connect/projects/#{project.id}/memories"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/flukebase_connect/projects/:project_id/memories" do
    let(:memory_params) do
      {
        memory: {
          memory_type: "fact",
          content: "New fact to remember",
          tags: ["testing"]
        }
      }
    end

    it "creates a new memory" do
      expect {
        post "/api/v1/flukebase_connect/projects/#{project.id}/memories",
             headers: auth_headers,
             params: memory_params,
             as: :json
      }.to change(ProjectMemory, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["memory"]["content"]).to eq("New fact to remember")
    end

    it "validates memory_type" do
      post "/api/v1/flukebase_connect/projects/#{project.id}/memories",
           headers: auth_headers,
           params: { memory: { memory_type: "invalid", content: "Test" } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/v1/flukebase_connect/projects/:project_id/memories/:id" do
    let!(:memory) { create(:project_memory, project: project, user: user, content: "Original") }

    it "updates the memory" do
      put "/api/v1/flukebase_connect/projects/#{project.id}/memories/#{memory.id}",
          headers: auth_headers,
          params: { memory: { content: "Updated content" } },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(memory.reload.content).to eq("Updated content")
    end
  end

  describe "DELETE /api/v1/flukebase_connect/projects/:project_id/memories/:id" do
    let!(:memory) { create(:project_memory, project: project, user: user) }

    it "deletes the memory" do
      expect {
        delete "/api/v1/flukebase_connect/projects/#{project.id}/memories/#{memory.id}",
               headers: auth_headers
      }.to change(ProjectMemory, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["deleted"]).to be true
    end
  end

  describe "POST /api/v1/flukebase_connect/projects/:project_id/memories/bulk_sync" do
    it "creates new memories with external_id" do
      params = {
        memories: [
          { external_id: "ext-1", memory_type: "fact", content: "First fact" },
          { external_id: "ext-2", memory_type: "gotcha", content: "First gotcha" }
        ]
      }

      expect {
        post "/api/v1/flukebase_connect/projects/#{project.id}/memories/bulk_sync",
             headers: auth_headers,
             params: params,
             as: :json
      }.to change(ProjectMemory, :count).by(2)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["summary"]["created"]).to eq(2)
    end

    it "updates existing memories by external_id" do
      existing = create(:project_memory,
                        project: project,
                        user: user,
                        external_id: "ext-existing",
                        content: "Original")

      params = {
        memories: [
          { external_id: "ext-existing", memory_type: "fact", content: "Updated" }
        ]
      }

      post "/api/v1/flukebase_connect/projects/#{project.id}/memories/bulk_sync",
           headers: auth_headers,
           params: params,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(existing.reload.content).to eq("Updated")
      json = JSON.parse(response.body)
      expect(json["summary"]["updated"]).to eq(1)
    end
  end

  describe "GET /api/v1/flukebase_connect/projects/:project_id/memories/conventions" do
    before do
      create(:project_memory, :convention,
             project: project,
             user: user,
             key: "testing",
             content: "Use RSpec")
    end

    it "returns conventions formatted for AI" do
      get "/api/v1/flukebase_connect/projects/#{project.id}/memories/conventions",
          headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["conventions"].length).to eq(1)
      expect(json["conventions"].first).to include("key", "value", "rationale")
    end
  end
end
