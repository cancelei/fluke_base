require 'rails_helper'

RSpec.describe 'Dashboard', type: :request do
  describe 'GET /dashboard' do
    let(:user) { create(:user) }
    let!(:mentor_project) do
      create(:project,
             name: 'Mentor Project',
             description: 'Looking for guidance',
             collaboration_type: Project::SEEKING_MENTOR,
             public_fields: ['name', 'description'])
    end

    before do
      sign_in user
    end

    it 'renders the dashboard overview with mentor opportunities' do
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dashboard')
      expect(response.body).to include('Mentor Project')
    end
  end
end
