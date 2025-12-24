require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  before do
    post user_session_path, params: {
      user: { email: user.email, password: user.password }
    }
  end

  describe "GET /index" do
    it "returns http success" do
      get "/projects"
      expect(response).to have_http_status(:success)
    end

    it "shows user's projects" do
      project # Create project
      get "/projects"
      expect(response.body).to include(project.name)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/projects/#{project.id}"
      expect(response).to have_http_status(:success)
    end

    it "shows project details" do
      get "/projects/#{project.id}"
      expect(response.body).to include(project.name)
      expect(response.body).to include(project.description)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/projects/new"
      expect(response).to have_http_status(:success)
    end

    it "shows new project form" do
      get "/projects/new"
      expect(response.body).to include("New Project")
    end
  end

  describe "POST /create" do
    it "creates a new project" do
      expect {
        post "/projects", params: {
          project: {
            name: "Test Project",
            description: "A test project",
            business_stage: "idea"
          }
        }
      }.to change(Project, :count).by(1)

      expect(response).to redirect_to(project_path(Project.last))
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/projects/#{project.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    it "updates the project" do
      patch "/projects/#{project.id}", params: {
        project: { name: "Updated Project" }
      }

      expect(response).to redirect_to(project_path(project.reload))
      expect(project.reload.name).to eq("Updated Project")
    end
  end
end
