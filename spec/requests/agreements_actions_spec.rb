require 'rails_helper'

RSpec.describe 'Agreements Actions (HTML fallbacks)', type: :request do
  let(:alice) { create(:user) }
  let(:bob)   { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, :mentorship, project:, initiator: alice, other_party: bob) }

  describe 'accept (HTML)' do
    it 'allows the user whose turn it is to accept and redirects with notice' do
      # On creation, other party (bob) has the turn
      sign_in bob
      patch accept_agreement_path(agreement)

      expect(response).to redirect_to(agreement_path(agreement))
      follow_redirect!
      expect(response.body).to include('accepted').or include('successfully')
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)
    end

    it 'prevents accept by the non-turn user and redirects with alert' do
      sign_in alice
      patch accept_agreement_path(agreement)
      expect(response).to redirect_to(agreement_path(agreement))
      expect(flash[:alert]).to be_present
      expect(agreement.reload.status).to eq(Agreement::PENDING)
    end
  end

  describe 'reject (HTML)' do
    it 'allows the user whose turn it is to reject and redirects with notice' do
      sign_in bob
      patch reject_agreement_path(agreement)
      expect(response).to redirect_to(agreement_path(agreement))
      follow_redirect!
      expect(response.body).to include('rejected').or include('successfully')
      expect(agreement.reload.status).to eq(Agreement::REJECTED)
    end

    it 'prevents reject by the non-turn user and redirects with alert' do
      sign_in alice
      patch reject_agreement_path(agreement)
      expect(response).to redirect_to(agreement_path(agreement))
      expect(flash[:alert]).to be_present
      expect(agreement.reload.status).to eq(Agreement::PENDING)
    end
  end

  describe 'cancel (HTML)' do
    it 'allows either party to cancel while pending' do
      sign_in alice
      patch cancel_agreement_path(agreement)
      expect(response).to redirect_to(agreement_path(agreement))
      follow_redirect!
      expect(response.body).to include('cancelled').or include('successfully')
      expect(agreement.reload.status).to eq(Agreement::CANCELLED)
    end
  end

  describe 'complete (HTML)' do
    it 'allows completion when accepted and redirects with notice' do
      # Accept first
      sign_in bob
      patch accept_agreement_path(agreement)
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)

      sign_in alice
      patch complete_agreement_path(agreement)
      expect(response).to redirect_to(agreement_path(agreement))
      follow_redirect!
      expect(response.body).to include('completed').or include('successfully')
      expect(agreement.reload.status).to eq(Agreement::COMPLETED)
    end
  end
end
