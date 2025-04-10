require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /update_role" do
    it "returns http success" do
      get "/users/update_role"
      expect(response).to have_http_status(:success)
    end
  end
end
