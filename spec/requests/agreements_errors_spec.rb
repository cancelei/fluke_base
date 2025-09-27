require 'rails_helper'

RSpec.describe 'Agreements Controller Error Branches', type: :request do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, :mentorship, project: project, initiator: alice, other_party: bob) }

  describe 'modification guards' do
    it 'prevents editing accepted agreements' do
      agreement.update!(status: Agreement::ACCEPTED)
      sign_in alice

      get edit_agreement_path(agreement)
      expect(response).to redirect_to(agreement_path(agreement))
      expect(flash[:alert]).to be_present

      patch agreement_path(agreement), params: { agreement: { tasks: 'Updated' } }
      expect(response).to redirect_to(agreement_path(agreement))
      expect(flash[:alert]).to be_present
    end
  end

  describe 'action transitions invalid cases (turbo_stream)' do
    it 'fails to complete when pending' do
      sign_in alice
      patch complete_agreement_path(agreement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('cannot be marked as completed').or(include('Unable'))
      expect(agreement.reload.status).to eq(Agreement::PENDING)
    end

    it 'fails to cancel when accepted' do
      agreement.update!(status: Agreement::ACCEPTED)
      sign_in alice
      patch cancel_agreement_path(agreement), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('You are not authorized to perform this action')
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
    end
  end

  describe 'new agreement ownership checks' do
    it 'redirects when missing project_id' do
      sign_in alice
      get new_agreement_path
      expect(response).to redirect_to(projects_path)
      expect(flash[:alert]).to match(/No project selected/i)
    end
  end

  describe 'counter_offer redirect' do
    it 'redirects to new with counter_to_id' do
      # By default, it is the other party's turn; they can make counter offers
      sign_in bob
      post counter_offer_agreement_path(agreement)
      expect(response).to redirect_to(new_agreement_path(counter_to_id: agreement.id, project_id: agreement.project_id, other_party_id: agreement.initiator_id))
    end
  end
end
