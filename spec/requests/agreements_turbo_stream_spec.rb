require 'rails_helper'

RSpec.describe 'Agreements Turbo Streams', type: :request do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  describe 'PATCH /agreements/:id/accept (turbo_stream)' do
    before { sign_in bob }

    it 'returns turbo stream updates and updates DB' do
      patch accept_agreement_path(agreement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')

      expect_stream_prepend('flash_messages')
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
    end

    it 'handles invalid transition gracefully' do
      agreement.update!(status: Agreement::ACCEPTED)
      patch accept_agreement_path(agreement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('You are not authorized to perform this action')
      expect_stream_prepend('flash_messages')
    end
  end

  describe 'GET /agreements (turbo_stream filters)' do
    before { sign_in alice }

    it 'updates filters and results areas' do
      get agreements_path, params: { status: 'pending' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect_stream_update('agreement_filters')
      expect_stream_update('agreement_results')
    end
  end
end
