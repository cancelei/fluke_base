class PeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_person, only: [ :show ]

  def explore
    @role = params[:role]
    @search = params[:search]
    @project_id = params[:project_id]

    users = User.joins(:roles).where(roles: { name: [ Role::MENTOR, Role::ENTREPRENEUR ] })
    users = users.where("(first_name ILIKE :q OR last_name ILIKE :q OR bio ILIKE :q)", q: "%#{@search}%") if @search.present?
    users = users.joins(:roles).where(roles: { name: @role }) if @role.present?
    if @project_id.present?
      users = users.joins(:projects).where(projects: { id: @project_id })
    end
    users = users.distinct.where.not(id: current_user.id)
                 .includes(:roles, :projects, :initiated_agreements, :received_agreements)
    @users = users.page(params[:page]).per(12)
  end

  def show
    @projects_involved = @person.projects + Project.joins(:agreements).where(agreements: { other_party_id: @person.id }).distinct
  end

  private

  def set_person
    @person = User.find(params[:id])
  end
end
