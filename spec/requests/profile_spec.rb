require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /profile" do
    it "returns http success" do
      get "/profile"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /profile/edit" do
    it "returns http success" do
      get "/profile/edit"
      expect(response).to have_http_status(:success)
    end
  end
end
