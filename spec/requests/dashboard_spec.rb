require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:user) { create(:user) }

  before do
    post user_session_path, params: {
      user: { email: user.email, password: user.password }
    }
  end

  describe "GET /index" do
    it "returns http success" do
      get "/dashboard"
      expect(response).to have_http_status(:success)
    end

    it "shows dashboard content for authenticated user" do
      get "/dashboard"
      expect(response.body).to include("Dashboard")
    end
  end
end
