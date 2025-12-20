require 'rails_helper'

# Lazy-loaded turbo frames (turbo_frame_tag with src: and loading: "lazy")
# expect HTML responses containing matching <turbo-frame> elements.
# They do NOT use turbo_stream format - that's only for explicit stream actions.
# See: https://turbo.hotwired.dev/reference/frames (Lazy-loaded frame documentation)
RSpec.describe 'Agreements Turbo Sections', type: :request do
  include ActionView::RecordIdentifier

  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice, public_fields: ['name'], repository_url: 'https://github.com/user/repo') }
  let!(:agreement) { create(:agreement, :with_participants, :accepted, project:, initiator: alice, other_party: bob) }

  before do
    sign_in alice
  end

  describe 'GET /agreements/:id/meetings_section' do
    let!(:meeting) { create(:meeting, agreement:, title: 'Weekly Sync') }

    it 'returns HTML with turbo-frame wrapper containing meeting content' do
      get meetings_section_agreement_path(agreement), headers: { 'Accept' => 'text/html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/html')
      # Lazy-loaded frames expect <turbo-frame> wrapper, not <turbo-stream>
      expect(response.body).to include("<turbo-frame id=\"#{dom_id(agreement)}_meetings\"")
      expect(response.body).to include('Weekly Sync')
    end
  end

  describe 'GET /agreements/:id/github_section' do
    let!(:github_log) { create(:github_log, project:, user: alice, commit_message: 'Initial commit') }

    it 'renders the GitHub section with turbo-frame wrapper and activity details' do
      get github_section_agreement_path(agreement), headers: { 'Accept' => 'text/html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/html')
      expect(response.body).to include("<turbo-frame id=\"#{dom_id(agreement)}_github\"")
      expect(response.body).to include('Initial commit')
    end
  end

  describe 'GET /agreements/:id/time_logs_section' do
    let!(:milestone) { create(:milestone, project:) }
    let!(:time_log) { create(:time_log, project:, milestone:, user: alice, description: 'Pairing session') }

    it 'renders the time log section with turbo-frame wrapper for agreement participants' do
      get time_logs_section_agreement_path(agreement), headers: { 'Accept' => 'text/html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/html')
      expect(response.body).to include("<turbo-frame id=\"#{dom_id(agreement)}_time_logs\"")
      expect(response.body).to include('Pairing session')
    end
  end

  describe 'GET /agreements/:id/counter_offers_section' do
    let!(:counter_offer) do
      create(:agreement, :with_participants, project:, initiator: bob, other_party: alice).tap do |counter|
        counter.agreement_participants.update_all(counter_agreement_id: agreement.id)
      end
    end

    it 'renders the counter offer history with turbo-frame wrapper' do
      get counter_offers_section_agreement_path(counter_offer), headers: { 'Accept' => 'text/html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/html')
      expect(response.body).to include("<turbo-frame id=\"#{dom_id(counter_offer)}_counter_offers\"")
      expect(response.body).to include('Negotiation History')
      expect(response.body).to include('Initial')
    end
  end
end
