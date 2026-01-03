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

  describe 'AI Productivity Insights' do
    let(:user) { create(:user) }
    let(:project) { create(:project, user:) }

    before do
      sign_in user
      user.update(selected_project: project)
    end

    context 'with no metrics' do
      it 'renders dashboard without errors' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
      end

      it 'does not show AI insights section when empty' do
        get dashboard_path

        # When no metrics, @ai_insights is empty
        expect(response.body).not_to include('AI Productivity Insights')
      end
    end

    context 'with time_saved metrics above threshold' do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { 'time_saved_minutes' => 30, 'efficiency_ratio' => 3.0 })
      end

      it 'displays AI insights section' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('AI Productivity Insights')
        expect(response.body).to include('Time Saved by AI')
      end
    end

    context 'with multiple metric types' do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { 'time_saved_minutes' => 60 })
        create(:ai_productivity_metric, :code_contribution, project:, user:,
               metric_data: { 'lines_added' => 500, 'commits' => 10 })
        create(:ai_productivity_metric, :task_velocity, project:, user:,
               metric_data: { 'tasks_completed' => 15, 'tasks_created' => 20 })
        create(:ai_productivity_metric, :token_efficiency, project:, user:,
               metric_data: { 'total_tokens' => 100000, 'estimated_cost_usd' => 1.50 })
      end

      it 'displays all insight types' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Time Saved by AI')
        expect(response.body).to include('Code Contributions')
        expect(response.body).to include('Task Velocity')
        expect(response.body).to include('Token Usage')
      end

      it 'includes insight card components' do
        get dashboard_path

        # InsightCardComponent renders data-controller for dismiss
        expect(response.body).to include('data-controller="insight-card"')
      end
    end

    context 'with metrics below threshold' do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { 'time_saved_minutes' => 2 }) # Below 5 min threshold
      end

      it 'does not show low-value insights' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('Time Saved by AI')
      end
    end

    context 'with onboarding progress' do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { 'time_saved_minutes' => 30 })
        user.create_onboarding_progress!(
          onboarding_stage: 3,
          milestones_completed: ['first_connection', 'first_ai_session']
        )
      end

      it 'shows onboarding progress indicator' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Setup progress')
      end
    end

    context 'with completed onboarding' do
      before do
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { 'time_saved_minutes' => 30 })
        user.create_onboarding_progress!(
          onboarding_stage: 5,
          milestones_completed: UserOnboardingProgress::MILESTONE_KEYS,
          insights_seen: UserOnboardingProgress::INSIGHT_KEYS,
          onboarding_completed_at: 1.day.ago
        )
      end

      it 'hides progress indicator when complete' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        # Progress indicator not shown at 100%
        expect(response.body).not_to include('Setup progress')
      end
    end

    context 'without selected project' do
      before do
        user.update(selected_project: nil)
        create(:ai_productivity_metric, :time_saved, project:, user:,
               metric_data: { 'time_saved_minutes' => 30 })
      end

      it 'falls back to first project' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('AI Productivity Insights')
      end
    end

    context 'when AiInsightsService raises error' do
      before do
        allow_any_instance_of(AiInsightsService).to receive(:dashboard_insights).and_raise(StandardError, 'test error')
      end

      it 'handles errors gracefully' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('AI Productivity Insights')
      end
    end
  end
end
