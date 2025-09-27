require 'rails_helper'

RSpec.describe 'Agreements Turbo Sections', type: :request do
  include ActionView::RecordIdentifier

  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice, public_fields: [ 'name' ], repository_url: 'https://github.com/user/repo') }
  let!(:agreement) { create(:agreement, :with_participants, :accepted, project: project, initiator: alice, other_party: bob) }

  before do
    sign_in alice
  end

  describe 'GET /agreements/:id/meetings_section' do
    let!(:meeting) { create(:meeting, agreement: agreement, title: 'Weekly Sync') }

    it 'returns a turbo stream payload with meeting content' do
      get meetings_section_agreement_path(agreement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include(dom_id(agreement) + '_meetings')
      expect(response.body).to include('Weekly Sync')
    end
  end

  describe 'GET /agreements/:id/github_section' do
    let!(:github_log) { create(:github_log, project: project, user: alice, commit_message: 'Initial commit') }

    it 'renders the GitHub section turbo stream with activity details' do
      get github_section_agreement_path(agreement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dom_id(agreement) + '_github')
      expect(response.body).to include('Initial commit')
    end
  end

  describe 'GET /agreements/:id/time_logs_section' do
    let!(:milestone) { create(:milestone, project: project) }
    let!(:time_log) { create(:time_log, project: project, milestone: milestone, user: alice, description: 'Pairing session') }

    it 'renders the time log turbo stream for agreement participants' do
      get time_logs_section_agreement_path(agreement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dom_id(agreement) + '_time_logs')
      expect(response.body).to include('Pairing session')
    end
  end

  describe 'GET /agreements/:id/counter_offers_section' do
    let!(:counter_offer) do
      create(:agreement, :with_participants, project: project, initiator: bob, other_party: alice).tap do |counter|
        counter.agreement_participants.update_all(counter_agreement_id: agreement.id)
      end
    end

    it 'renders the counter offer history' do
      get counter_offers_section_agreement_path(counter_offer), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dom_id(counter_offer) + '_counter_offers')
      expect(response.body).to include('Negotiation History')
      expect(response.body).to include('Initial Agreement')
    end
  end
end
