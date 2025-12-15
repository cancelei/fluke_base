class PeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_person, only: [ :show ]

  def explore
    @role = params[:role]
    @search = params[:search]
    @project_id = params[:project_id]

    # Handle "propose_for_project" flow - when user is looking for collaborators
    if params[:propose_for_project].present?
      @propose_for_project = Project.find_by(id: params[:propose_for_project])
      if @propose_for_project && @propose_for_project.user_id == current_user.id
        flash.now[:notice] = "Select a person below to propose an agreement for \"#{@propose_for_project.name}\""
      end
    end

    query = PeopleSearchQuery.new(current_user, params)
    @users = query.results
  end

  def show
    # SECURITY FIX: Filter projects based on current user's access
    all_person_projects = @person.projects + Project.joins(agreements: :agreement_participants)
                                                    .where(agreement_participants: { user_id: @person.id })
                                                    .distinct

    # Only show projects that current_user has access to view
    @projects_involved = all_person_projects.select do |project|
      policy(project).show?
    end.uniq

    # Only count shared agreements where current_user is actually a party
    @shared_agreements_count = Agreement.joins(:agreement_participants)
                                        .where(agreement_participants: { user_id: [ current_user.id, @person.id ] })
                                        .group("agreements.id")
                                        .having("COUNT(DISTINCT agreement_participants.user_id) = 2")
                                        .count
                                        .size
  end

  private

  def set_person
    @person = User.find(params[:id])
  end
end
