require 'rails_helper'

RSpec.describe 'Agreements', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /agreements' do
    it 'renders the full index page' do
      get agreements_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Your Projects')
      expect(response.body).to include('<html')
    end

    it 'renders the agreement results partial for turbo frame requests' do
      get agreements_path, headers: { 'Turbo-Frame' => 'agreement_results' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Your Projects')
      expect(response.body).not_to include('<html')
    end

    it 'returns turbo stream updates when requested' do
      get agreements_path(format: :turbo_stream)

      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('turbo-stream action="update"')
      expect(response.body).to include('agreement_results')
    end
  end
end
