require 'rails_helper'

RSpec.describe "Onboardings", type: :request do
  describe "GET /entrepreneur" do
    it "returns http success" do
      get "/onboarding/entrepreneur"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /mentor" do
    it "returns http success" do
      get "/onboarding/mentor"
      expect(response).to have_http_status(:success)
    end
  end
end
