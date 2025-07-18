class DashboardController < ApplicationController
  def index
    # Redirect to onboarding if the user hasn't completed onboarding for any role
    if current_user.requires_onboarding?
      path = current_user.current_onboarding_path
      if path == :entrepreneur
        redirect_to onboarding_entrepreneur_path and return
      elsif path == :mentor
        redirect_to onboarding_mentor_path and return
      end
    end

    query = DashboardQuery.new(current_user)
    @projects = query.recent_projects
    @agreements = query.recent_agreements
    @upcoming_meetings = query.upcoming_meetings

    # If the user is a mentor, find projects they can explore
    @explorable_projects = query.mentor_opportunities

    # Print out collaboration types of found projects
    @explorable_projects.each_with_index do |p, i|
      Rails.logger.debug "DEBUG: Project #{i+1}: #{p.name}, collaboration_type: #{p.collaboration_type}"
    end
  end
end
