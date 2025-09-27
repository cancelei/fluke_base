# frozen_string_literal: true

require 'rails_helper'

describe AgreementsController, type: :controller do
  let(:user) { create(:user, :alice) }
  let(:project) { create(:project, user: user) }
  let(:other_user) { create(:user, :bob) }
  let(:agreement) { create(:agreement, :with_participants, project: project, initiator: user, other_party: other_user) }

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(true)
    allow(controller).to receive(:set_selected_project).and_return(nil)
  end

  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show' do
    it 'returns success' do
      get :show, params: { id: agreement.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let(:agreement_params) { attributes_for(:agreement, project_id: project.id, other_party_user_id: other_user.id, initiator_user_id: user.id) }

    it 'creates a new agreement and redirects to index' do
      expect {
        post :create, params: { agreement: agreement_params }
      }.to change(Agreement, :count).by(1)
      expect(response).to redirect_to(agreements_path)
    end
  end

  describe 'PATCH #update' do
    it 'updates the agreement' do
      patch :update, params: { id: agreement.id, agreement: { tasks: 'Updated tasks' } }
      agreement.reload
      expect(agreement.tasks).to eq('Updated tasks')
      expect(response).to redirect_to(agreement)
    end
  end

  describe 'POST #accept' do
    it 'accepts the agreement' do
      allow(controller).to receive(:current_user).and_return(other_user)
      post :accept, params: { id: agreement.id }
      expect(response).to redirect_to(agreement)
    end
  end

  describe 'POST #reject' do
    it 'rejects the agreement' do
      allow(controller).to receive(:current_user).and_return(other_user)
      post :reject, params: { id: agreement.id }
      expect(response).to redirect_to(agreement)
    end
  end

  describe 'POST #complete' do
    it 'completes the agreement' do
      post :complete, params: { id: agreement.id }
      expect(response).to redirect_to(agreement)
    end
  end

  describe 'POST #cancel' do
    it 'cancels the agreement' do
      post :cancel, params: { id: agreement.id }
      expect(response).to redirect_to(agreement)
    end
  end
end
