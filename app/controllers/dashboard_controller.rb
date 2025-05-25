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

    @projects = current_user.projects.order(created_at: :desc).limit(5)
    @agreements = current_user.all_agreements.order(created_at: :desc).limit(5)
    @upcoming_meetings = Meeting.joins(:agreement)
                               .where("agreements.initiator_id = ? OR agreements.other_party_id = ?",
                                      current_user.id, current_user.id)
                               .upcoming.limit(3)

    # If the user is a mentor, find projects they can explore
    if current_user.has_role?(:mentor)
      Rails.logger.debug "DEBUG: User #{current_user.id} has mentor role, finding explorable projects"

      # First check how many projects exist overall
      total_projects = Project.count
      Rails.logger.debug "DEBUG: Total projects in the system: #{total_projects}"

      # Check how many projects aren't owned by this mentor
      other_projects = Project.where.not(user_id: current_user.id).count
      Rails.logger.debug "DEBUG: Projects not owned by this mentor: #{other_projects}"

      # Check how many agreements this mentor has
      other_party_agreements = Agreement.where(other_party_id: current_user.id).count
      Rails.logger.debug "DEBUG: Mentor has #{other_party_agreements} agreement(s)"

      # Check projects with the collaboration_type field set
      projects_with_collab_type = Project.where.not(collaboration_type: [ nil, "" ]).count
      Rails.logger.debug "DEBUG: Projects with collaboration_type set: #{projects_with_collab_type}"

      # Check mentor seeking projects
      mentor_seeking_projects = Project.where("collaboration_type = ? OR collaboration_type = ?", Project::SEEKING_MENTOR, Project::SEEKING_BOTH).count
      Rails.logger.debug "DEBUG: Projects seeking mentors: #{mentor_seeking_projects}"

      # The actual query for explorable projects
      @explorable_projects = Project.joins(:user)
                                    .where.not(user_id: current_user.id)
                                    .where.not(id: Agreement.where(other_party_id: current_user.id).select(:project_id))
                                    .where("collaboration_type = ? OR collaboration_type = ?", Project::SEEKING_MENTOR, Project::SEEKING_BOTH)
                                    .order(created_at: :desc)
                                    .limit(5)

      Rails.logger.debug "DEBUG: Found #{@explorable_projects.count} explorable projects for mentor"

      # Print out collaboration types of found projects
      @explorable_projects.each_with_index do |p, i|
        Rails.logger.debug "DEBUG: Project #{i+1}: #{p.name}, collaboration_type: #{p.collaboration_type}"
      end
    else
      Rails.logger.debug "DEBUG: User #{current_user.id} does not have mentor role"
    end
  end
end
