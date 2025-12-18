# frozen_string_literal: true

class ProjectMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_membership, only: [ :update, :destroy ]
  before_action :authorize_manage_members, except: [ :index, :accept, :reject ]

  def index
    authorize @project, :view_team?
    @memberships = @project.project_memberships.includes(:user, :invited_by).order(:role, :created_at)
  end

  def new
    @membership = @project.project_memberships.build
    @available_users = User.where.not(id: @project.project_memberships.pluck(:user_id))
                           .order(:first_name, :last_name)
                           .limit(50)
  end

  def create
    @membership = @project.project_memberships.build(membership_params)
    @membership.invited_by = current_user
    @membership.invited_at = Time.current

    # Ensure user can't assign roles higher than their own
    unless can_assign_role?(@membership.role)
      return redirect_to project_memberships_path(@project),
                         alert: "You cannot assign a role higher than your own."
    end

    if @membership.save
      redirect_to project_memberships_path(@project),
                  notice: "#{@membership.user.full_name} has been invited as #{@membership.role_label}."
    else
      @available_users = User.where.not(id: @project.project_memberships.pluck(:user_id))
                             .order(:first_name, :last_name)
                             .limit(50)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Check if user can change to the new role
    unless can_assign_role?(membership_params[:role])
      return redirect_to project_memberships_path(@project),
                         alert: "You cannot assign a role higher than your own."
    end

    # Prevent changing owner's role
    if @membership.owner? && !@project.user_is_owner?(current_user)
      return redirect_to project_memberships_path(@project),
                         alert: "You cannot change the owner's role."
    end

    if @membership.update(membership_params)
      redirect_to project_memberships_path(@project),
                  notice: "#{@membership.user.full_name}'s role has been updated to #{@membership.role_label}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Prevent removing the owner
    if @membership.owner?
      return redirect_to project_memberships_path(@project),
                         alert: "You cannot remove the project owner."
    end

    # Prevent removing users with higher roles
    user_membership = @project.membership_for(current_user)
    unless user_membership&.higher_role_than?(@membership) || @project.user_is_owner?(current_user)
      return redirect_to project_memberships_path(@project),
                         alert: "You cannot remove a member with an equal or higher role."
    end

    user_name = @membership.user.full_name
    @membership.destroy

    redirect_to project_memberships_path(@project),
                notice: "#{user_name} has been removed from the project."
  end

  # Accept a pending membership invitation
  def accept
    @membership = @project.project_memberships.find(params[:id])

    unless @membership.user_id == current_user.id && @membership.pending?
      return redirect_to dashboard_path, alert: "You cannot accept this invitation."
    end

    @membership.accept!
    redirect_to project_path(@project),
                notice: "You have joined #{@project.name} as #{@membership.role_label}."
  end

  # Reject a pending membership invitation
  def reject
    @membership = @project.project_memberships.find(params[:id])

    unless @membership.user_id == current_user.id && @membership.pending?
      return redirect_to dashboard_path, alert: "You cannot reject this invitation."
    end

    project_name = @project.name
    @membership.destroy
    redirect_to dashboard_path,
                notice: "You have declined the invitation to join #{project_name}."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_membership
    @membership = @project.project_memberships.find(params[:id])
  end

  def membership_params
    permitted = params.require(:project_membership).permit(:user_id)
    permitted[:role] = sanitized_role
    permitted
  end

  # Sanitize role separately to prevent privilege escalation
  # Owner role is never assignable through mass assignment
  def sanitized_role
    role = params.dig(:project_membership, :role).to_s.downcase
    assignable_roles = ProjectMembership::ROLES - [ "owner" ]
    assignable_roles.include?(role) ? role : "member"
  end

  def authorize_manage_members
    authorize @project, :manage_members?
  rescue Pundit::NotAuthorizedError
    redirect_to project_path(@project), alert: "You don't have permission to manage team members."
  end

  def can_assign_role?(role)
    return true if @project.user_is_owner?(current_user)

    user_membership = @project.membership_for(current_user)
    return false unless user_membership

    user_membership.can_manage_role?(role)
  end
end
