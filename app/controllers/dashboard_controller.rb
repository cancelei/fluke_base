class DashboardController < ApplicationController
  def index
    query = DashboardQuery.new(current_user)

    # Projects ordered by GitHub activity (most recent commits first)
    @projects = query.projects_by_activity

    # Recent GitHub activity across all accessible projects
    @recent_activity = query.recent_activity
    @activity_summary = query.activity_summary

    # Agreements and meetings
    @agreements = query.recent_agreements
    @upcoming_meetings = query.upcoming_meetings

    # Show explorable projects to all users
    @explorable_projects = query.mentor_opportunities

    # AI Productivity insights for onboarding
    @ai_insights = load_ai_insights
  end

  private

  def load_ai_insights
    return [] unless current_user

    project = current_user.selected_project || current_user.projects.order(:created_at).first
    service = AiInsightsService.new(user: current_user, project:)
    service.dashboard_insights
  rescue StandardError => e
    Rails.logger.error("Failed to load AI insights: #{e.message}")
    []
  end
end
