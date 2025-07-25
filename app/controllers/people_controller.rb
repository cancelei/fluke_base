class PeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_person, only: [ :show ]

  def explore
    @role = params[:role]
    @search = params[:search]
    @project_id = params[:project_id]

    query = PeopleSearchQuery.new(current_user, params)
    @users = query.results
  end

  def show
    @projects_involved = @person.projects + Project.joins(agreements: :agreement_participants).where(agreement_participants: { user_id: @person.id }).distinct
  end

  private

  def set_person
    @person = User.find(params[:id])
  end
end
