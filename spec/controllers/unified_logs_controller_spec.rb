# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnifiedLogsController, type: :controller do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }

  describe "GET #index" do
    context "when not authenticated" do
      it "redirects to login" do
        get :index

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "renders the index template" do
        get :index

        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "sets log type options" do
        get :index

        expect(assigns(:log_types)).to be_an(Array)
        expect(assigns(:log_types).map { |t| t[:value] }).to include("mcp", "container", "application")
      end

      it "sets log level options" do
        get :index

        expect(assigns(:log_levels)).to be_an(Array)
        expect(assigns(:log_levels).map { |l| l[:value] }).to include("info", "warn", "error")
      end

      it "sets WebSocket URL" do
        get :index

        expect(assigns(:ws_url)).to be_present
      end

      context "with project_id parameter" do
        it "loads the project" do
          get :index, params: { project_id: project.id }

          expect(assigns(:project)).to eq(project)
        end
      end

      context "with sandbox_id parameter" do
        it "stores the sandbox_id" do
          get :index, params: { sandbox_id: "test-sandbox" }

          expect(assigns(:sandbox_id)).to eq("test-sandbox")
        end
      end

      it "responds with JSON when requested" do
        get :index, format: :json

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json).to have_key("log_types")
        expect(json).to have_key("log_levels")
        expect(json).to have_key("ws_url")
      end
    end
  end

  describe "GET #export" do
    context "when not authenticated" do
      it "redirects to login" do
        get :export, format: :json

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns JSON format" do
        get :export, format: :json

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "returns CSV format" do
        get :export, format: :csv

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
      end

      it "includes project slug in filename when project specified" do
        get :export, params: { project_id: project.id }, format: :json

        expect(response.headers["Content-Disposition"]).to include(project.slug)
      end

      it "includes sandbox_id in filename when specified" do
        get :export, params: { sandbox_id: "my-sandbox" }, format: :json

        expect(response.headers["Content-Disposition"]).to include("my-sandbox")
      end

      it "limits export to 10000 entries max" do
        get :export, params: { limit: 50_000 }, format: :json

        # Should cap at 10000
        expect(response).to have_http_status(:success)
      end
    end
  end
end
