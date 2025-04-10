require 'rails_helper'

RSpec.describe "Mentors", type: :request do
  describe "GET /explore" do
    it "returns http success" do
      get "/mentors/explore"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/mentors/show"
      expect(response).to have_http_status(:success)
    end
  end
end
