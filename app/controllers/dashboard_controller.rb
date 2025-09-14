class DashboardController < ApplicationController
  def index
    # No role-based onboarding required - roles are now purely for categorization
    query = DashboardQuery.new(current_user)
    @projects = query.recent_projects
    @agreements = query.recent_agreements
    @upcoming_meetings = query.upcoming_meetings

    # Show explorable projects to all users regardless of role
    @explorable_projects = query.mentor_opportunities
  end
end
