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
  end
end
