require 'rails_helper'

RSpec.describe 'Agreements Integration', type: :request do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let(:milestone) { create(:milestone, project: project) }

  before { sign_in alice }

  describe 'Agreement workflow' do
    it 'completes full agreement lifecycle using the test DB' do
      post '/agreements', params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: Agreement::MENTORSHIP,
          payment_type: Agreement::HOURLY,
          hourly_rate: 75.0,
          weekly_hours: 10,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: 'Help with development',
          milestone_ids: [ milestone.id ]
        }
      }

      expect(response).to redirect_to('/agreements')
      agreement = Agreement.order(:created_at).last
      expect(agreement.status).to eq(Agreement::PENDING)

      sign_in bob
      patch "/agreements/#{agreement.id}/accept", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:success)
      expect(agreement.reload.status).to eq(Agreement::ACCEPTED)

      sign_in alice
      patch "/agreements/#{agreement.id}/complete", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to have_http_status(:success)
      expect(agreement.reload.status).to eq(Agreement::COMPLETED)
    end

    it 'creates a co-founder equity agreement successfully' do
      post '/agreements', params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: Agreement::CO_FOUNDER,
          payment_type: Agreement::EQUITY,
          equity_percentage: 25.0,
          start_date: 1.week.from_now.to_date,
          end_date: 8.weeks.from_now.to_date,
          tasks: 'Co-founder responsibilities'
        }
      }

      expect(response).to redirect_to('/agreements')
      created = Agreement.order(:created_at).last
      expect(created.agreement_type).to eq(Agreement::CO_FOUNDER)
      expect(created.payment_type).to eq(Agreement::EQUITY)
      expect(created.equity_percentage).to eq(25.0)
      expect(created.status).to eq(Agreement::PENDING)
    end

    it 'handles counter offers end-to-end (minimal)' do
      # Original agreement (co-founder to avoid milestone/weekly_hours constraints)
      original = create(:agreement, :with_participants, :co_founder, project: project, initiator: alice, other_party: bob)

      sign_in bob
      post '/agreements', params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: alice.id,
          agreement_type: Agreement::CO_FOUNDER,
          payment_type: Agreement::EQUITY,
          equity_percentage: 20.0,
          weekly_hours: 10,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: 'Partner terms update',
          counter_agreement_id: original.id
        }
      }

      expect(response).to redirect_to('/agreements')
      expect(original.reload.status).to eq(Agreement::COUNTERED)
      counter_offer = Agreement.order(:created_at).last
      expect(counter_offer.counter_to).to eq(original)
      expect(counter_offer.equity_percentage).to eq(20.0)
    end
  end

  describe 'Error handling' do
    it 'handles invalid agreement creation with proper status' do
      post '/agreements', params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: alice.id, # invalid: same as initiator
          agreement_type: Agreement::MENTORSHIP
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      # Error should be surfaced in flash or body
      expect(flash[:alert]).to be_present.or(
        satisfy { |_| response.body.match?(/cannot|can't|error/i) }
      )
    end

    it 'responds 422 when mentorship missing milestone_ids' do
      post '/agreements', params: {
        agreement: {
          project_id: project.id,
          other_party_user_id: bob.id,
          agreement_type: Agreement::MENTORSHIP,
          payment_type: Agreement::HOURLY,
          hourly_rate: 50,
          weekly_hours: 10,
          start_date: 1.week.from_now.to_date,
          end_date: 4.weeks.from_now.to_date,
          tasks: 'Mentorship tasks',
          milestone_ids: []
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'restricts unauthorized access to show' do
      other_agreement = create(:agreement, :with_participants, :mentorship, project: create(:project))

      get "/agreements/#{other_agreement.id}"
      expect(response).to redirect_to('/agreements')
      expect(flash[:alert]).to be_present
    end
  end
end
