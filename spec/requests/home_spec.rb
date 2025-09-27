require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "shows home page content" do
      get "/"
      expect(response.body).to include("FlukeBase")
    end
  end
end
