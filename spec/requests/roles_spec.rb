require 'rails_helper'

RSpec.describe "Roles", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/roles/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /request_role" do
    it "returns http success" do
      get "/roles/request_role"
      expect(response).to have_http_status(:success)
    end
  end
end
