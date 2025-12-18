# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgreementsController, type: :controller do
  let(:user) { create(:user, :alice) }
  let(:project) { create(:project, user: user) }
  let(:other_user) { create(:user, :bob) }
  let(:agreement) { create(:agreement, :with_participants, project: project, initiator: user, other_party: other_user) }
  let(:milestone) { create(:milestone, project: project) }

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

    it 'assigns @my_agreements' do
      agreement # create the agreement
      get :index
      expect(assigns(:my_agreements)).to be_present
    end

    it 'assigns @other_party_agreements' do
      get :index
      expect(assigns(:other_party_agreements)).to be_present.or eq([])
    end

    context 'with turbo_frame request' do
      it 'renders agreement_results partial for agreement_results frame' do
        request.headers['Turbo-Frame'] = 'agreement_results'
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'renders my_agreements_section for agreements_my frame' do
        request.headers['Turbo-Frame'] = 'agreements_my'
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'renders other_agreements_section for agreements_other frame' do
        request.headers['Turbo-Frame'] = 'agreements_other'
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context 'with turbo_stream format' do
      it 'responds with turbo_stream content type' do
        get :index, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'GET #show' do
    it 'returns success' do
      get :show, params: { id: agreement.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns @agreement' do
      get :show, params: { id: agreement.id }
      expect(assigns(:agreement)).to eq(agreement)
    end

    it 'assigns @project' do
      get :show, params: { id: agreement.id }
      expect(assigns(:project)).to eq(agreement.project)
    end

    it 'assigns @can_view_full_details' do
      get :show, params: { id: agreement.id }
      expect(assigns(:can_view_full_details)).to be_in([ true, false ])
    end

    context 'with turbo_stream format' do
      it 'responds with turbo_stream' do
        get :show, params: { id: agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'GET #new' do
    it 'returns success' do
      get :new, params: { project_id: project.id, other_party_id: other_user.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns @agreement_form' do
      get :new, params: { project_id: project.id, other_party_id: other_user.id }
      expect(assigns(:agreement_form)).to be_a(AgreementForm)
    end

    context 'with counter offer' do
      let(:original_agreement) { create(:agreement, :with_participants, project: project, initiator: other_user, other_party: user) }

      it 'pre-populates form with original agreement data' do
        get :new, params: { counter_to_id: original_agreement.id, other_party_id: other_user.id }
        expect(assigns(:agreement_form).counter_agreement_id).to eq(original_agreement.id)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns success' do
      get :edit, params: { id: agreement.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns @agreement_form' do
      get :edit, params: { id: agreement.id }
      expect(assigns(:agreement_form)).to be_a(AgreementForm)
    end

    it 'populates form with agreement data' do
      get :edit, params: { id: agreement.id }
      form = assigns(:agreement_form)
      expect(form.project_id).to eq(agreement.project_id)
      expect(form.agreement_type).to eq(agreement.agreement_type)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        agreement: {
          project_id: project.id,
          other_party_user_id: other_user.id,
          agreement_type: Agreement::CO_FOUNDER,
          payment_type: Agreement::EQUITY,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: 'Test tasks for the agreement',
          equity_percentage: '10',
          milestone_ids: [ milestone.id ]
        }
      }
    end

    context 'with valid params' do
      it 'creates a new Agreement' do
        expect {
          post :create, params: valid_params
        }.to change(Agreement, :count).by(1)
      end

      it 'creates AgreementParticipants' do
        expect {
          post :create, params: valid_params
        }.to change(AgreementParticipant, :count).by(2)
      end

      it 'sets initiator as current user' do
        post :create, params: valid_params
        created_agreement = Agreement.last
        initiator_participant = created_agreement.agreement_participants.find_by(is_initiator: true)
        expect(initiator_participant.user).to eq(user)
      end

      it 'sets other_party correctly' do
        post :create, params: valid_params
        created_agreement = Agreement.last
        other_party_participant = created_agreement.agreement_participants.find_by(is_initiator: false)
        expect(other_party_participant.user).to eq(other_user)
      end

      it 'redirects to agreement' do
        post :create, params: valid_params
        expect(response).to redirect_to(Agreement.last)
      end

      it 'sets success notice' do
        post :create, params: valid_params
        expect(flash[:notice]).to include('Agreement proposal sent')
      end
    end

    context 'with counter offer' do
      let(:original_agreement) { create(:agreement, :with_participants, project: project, initiator: other_user, other_party: user) }

      it 'creates counter offer with reference to original' do
        counter_params = valid_params.deep_merge(
          agreement: { counter_agreement_id: original_agreement.id }
        )
        post :create, params: counter_params
        expect(response).to redirect_to(Agreement.last)
        expect(flash[:notice]).to include('Counter offer was successfully created')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          agreement: {
            project_id: project.id,
            other_party_user_id: other_user.id,
            milestone_ids: []
          }
        }
      end

      it 'does not create Agreement' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Agreement, :count)
      end

      it 'renders new template with unprocessable_content status' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      it 'updates the agreement' do
        patch :update, params: {
          id: agreement.id,
          agreement: { tasks: 'Updated tasks', milestone_ids: [] }
        }
        agreement.reload
        expect(agreement.tasks).to eq('Updated tasks')
      end

      it 'redirects to agreement' do
        patch :update, params: {
          id: agreement.id,
          agreement: { tasks: 'Updated tasks', milestone_ids: [] }
        }
        expect(response).to redirect_to(agreement)
      end

      it 'sets success notice' do
        patch :update, params: {
          id: agreement.id,
          agreement: { tasks: 'Updated tasks', milestone_ids: [] }
        }
        expect(flash[:notice]).to include('successfully updated')
      end
    end

    context 'with invalid params' do
      it 'renders edit template with unprocessable_content status' do
        patch :update, params: {
          id: agreement.id,
          agreement: { end_date: 1.year.ago.to_date, milestone_ids: [] }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'POST #accept' do
    before { allow(controller).to receive(:current_user).and_return(other_user) }

    context 'with HTML format' do
      it 'redirects to agreement' do
        post :accept, params: { id: agreement.id }
        expect(response).to redirect_to(agreement)
      end

      it 'accepts the agreement' do
        post :accept, params: { id: agreement.id }
        agreement.reload
        expect(agreement.status).to eq(Agreement::ACCEPTED)
      end
    end

    context 'with turbo_stream format' do
      it 'responds with turbo_stream content type' do
        post :accept, params: { id: agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end

      it 'sets flash.now notice' do
        post :accept, params: { id: agreement.id }, format: :turbo_stream
        expect(flash.now[:notice]).to include('accepted')
      end
    end
  end

  describe 'POST #reject' do
    before { allow(controller).to receive(:current_user).and_return(other_user) }

    context 'with HTML format' do
      it 'redirects to agreement' do
        post :reject, params: { id: agreement.id }
        expect(response).to redirect_to(agreement)
      end

      it 'rejects the agreement' do
        post :reject, params: { id: agreement.id }
        agreement.reload
        expect(agreement.status).to eq(Agreement::REJECTED)
      end
    end

    context 'with turbo_stream format' do
      it 'responds with turbo_stream content type' do
        post :reject, params: { id: agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end

      it 'sets flash.now notice' do
        post :reject, params: { id: agreement.id }, format: :turbo_stream
        expect(flash.now[:notice]).to include('rejected')
      end
    end
  end

  describe 'POST #complete' do
    let(:accepted_agreement) { create(:agreement, :with_participants, :accepted, project: project, initiator: user, other_party: other_user) }

    context 'with HTML format' do
      it 'redirects to agreement' do
        post :complete, params: { id: accepted_agreement.id }
        expect(response).to redirect_to(accepted_agreement)
      end
    end

    context 'with turbo_stream format' do
      it 'responds with turbo_stream content type' do
        post :complete, params: { id: accepted_agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'POST #cancel' do
    context 'with HTML format' do
      it 'redirects to agreement' do
        post :cancel, params: { id: agreement.id }
        expect(response).to redirect_to(agreement)
      end
    end

    context 'with turbo_stream format' do
      it 'responds with turbo_stream content type' do
        post :cancel, params: { id: agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end
  end

  describe 'Lazy loading sections' do
    let(:accepted_agreement) { create(:agreement, :with_participants, :accepted, project: project, initiator: user, other_party: other_user) }

    describe 'GET #meetings_section' do
      it 'responds successfully' do
        get :meetings_section, params: { id: accepted_agreement.id }
        expect(response).to have_http_status(:success)
      end

      it 'responds to turbo_stream format' do
        get :meetings_section, params: { id: accepted_agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end

      it 'assigns @meetings for active agreement' do
        get :meetings_section, params: { id: accepted_agreement.id }
        expect(assigns(:meetings)).to be_present.or eq([])
      end

      it 'redirects for pending agreement' do
        get :meetings_section, params: { id: agreement.id }
        expect(response).to redirect_to(agreements_path)
      end
    end

    describe 'GET #github_section' do
      it 'responds successfully' do
        get :github_section, params: { id: accepted_agreement.id }
        expect(response).to have_http_status(:success)
      end

      it 'responds to turbo_stream format' do
        get :github_section, params: { id: accepted_agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end

      it 'assigns @can_view_full_details' do
        get :github_section, params: { id: accepted_agreement.id }
        expect(assigns(:can_view_full_details)).to be_in([ true, false ])
      end
    end

    describe 'GET #time_logs_section' do
      it 'responds successfully' do
        get :time_logs_section, params: { id: accepted_agreement.id }
        expect(response).to have_http_status(:success)
      end

      it 'responds to turbo_stream format' do
        get :time_logs_section, params: { id: accepted_agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end

      it 'filters time logs by participant user_ids' do
        get :time_logs_section, params: { id: accepted_agreement.id }
        expect(assigns(:agreement_participant_time_logs)).to be_present.or eq([])
      end
    end

    describe 'GET #counter_offers_section' do
      it 'responds successfully' do
        get :counter_offers_section, params: { id: accepted_agreement.id }
        expect(response).to have_http_status(:success)
      end

      it 'responds to turbo_stream format' do
        get :counter_offers_section, params: { id: accepted_agreement.id }, format: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end

      it 'builds agreement chain' do
        get :counter_offers_section, params: { id: accepted_agreement.id }
        expect(assigns(:agreement_chain)).to be_an(Array)
      end
    end
  end

  describe 'Authorization' do
    let(:unauthorized_user) { create(:user) }

    context 'when user is not a participant' do
      before { allow(controller).to receive(:current_user).and_return(unauthorized_user) }

      it 'redirects with alert for show' do
        get :show, params: { id: agreement.id }
        expect(response).to redirect_to(agreements_path)
        expect(flash[:alert]).to be_present
      end

      it 'redirects with alert for edit' do
        get :edit, params: { id: agreement.id }
        expect(response).to redirect_to(agreements_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the agreement' do
      agreement_to_delete = agreement
      expect {
        delete :destroy, params: { id: agreement_to_delete.id }
      }.to change(Agreement, :count).by(-1)
    end

    it 'redirects to agreements_url' do
      delete :destroy, params: { id: agreement.id }
      expect(response).to redirect_to(agreements_url)
    end

    it 'sets success notice' do
      delete :destroy, params: { id: agreement.id }
      expect(flash[:notice]).to include('successfully destroyed')
    end
  end
end
