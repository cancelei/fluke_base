# frozen_string_literal: true

class ProjectMembershipPolicy < ApplicationPolicy
  def index?
    return false unless signed_in?

    # User must be able to view the project to see its memberships
    ProjectPolicy.new(user, record.respond_to?(:project) ? record.project : nil).show?
  end

  def show?
    return true if admin?
    return false unless signed_in?

    # User can view membership if they're the member or if they have access to the project
    record.user_id == user.id || project_admin?
  end

  def create?
    return true if admin?
    return false unless signed_in?

    # Only project admins can create memberships (invite members)
    project_admin?
  end

  def new?
    create?
  end

  def update?
    return true if admin?
    return false unless signed_in?

    # Project owner can manage memberships without needing an explicit membership row
    return !record.owner? if record.project.user_id == user.id

    # Only project admins can update memberships
    # They can only modify roles lower than their own
    return false unless project_admin?

    # Check role hierarchy - admins can't modify owner roles or roles equal to/higher than theirs
    current_user_membership = record.project.membership_for(user)
    return false unless current_user_membership

    current_user_membership.higher_role_than?(record)
  end

  def edit?
    update?
  end

  def destroy?
    return true if admin?
    return false unless signed_in?

    # Users can remove themselves (leave project)
    return true if record.user_id == user.id && !record.owner?

    # Project owner can remove non-owner memberships
    return !record.owner? if record.project.user_id == user.id

    # Project admins can remove members with lower roles
    return false unless project_admin?

    current_user_membership = record.project.membership_for(user)
    return false unless current_user_membership

    # Can't remove owner or members with equal/higher role
    !record.owner? && current_user_membership.higher_role_than?(record)
  end

  # Additional permission methods

  def accept?
    return true if admin?
    return false unless signed_in?

    # Only the invited user can accept their membership
    record.user_id == user.id && record.pending?
  end

  def change_role?
    update?
  end

  def resend_invitation?
    return true if admin?
    return false unless signed_in?

    project_admin? && record.pending?
  end

  class Scope < Scope
    def resolve
      if user.nil?
        # Unauthenticated users can't see memberships
        scope.none
      elsif user.admin?
        # Admins see all memberships
        scope.all
      else
        # Users see:
        # 1. Their own memberships
        # 2. Memberships for projects where they're admins
        scope.left_joins(:project)
             .where(
               "project_memberships.user_id = :user_id OR
                projects.id IN (
                  SELECT project_id FROM project_memberships
                  WHERE user_id = :user_id
                  AND role IN ('owner', 'admin')
                )",
               user_id: user.id
             )
             .distinct
      end
    end
  end

  protected

  def project_admin?
    return false unless record&.project

    record.project.user_is_admin?(user)
  end
end
