# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can view their own projects list
  end

  def show?
    return false unless user

    # Owner always has access
    return true if record.user_id == user.id

    # Check membership or agreement access
    return true if record.user_has_access?(user)

    # Allow viewing publicly discoverable (non-stealth) projects
    return true if record.publicly_discoverable?

    false
  end

  def create?
    user.present?
  end

  def update?
    return false unless user
    record.user_is_admin?(user)
  end

  def destroy?
    return false unless user
    record.user_is_owner?(user)
  end

  def explore?
    true # All authenticated users can explore public projects
  end

  # Membership management permissions
  def manage_members?
    return false unless user
    record.user_is_admin?(user)
  end

  def invite_member?
    manage_members?
  end

  def remove_member?
    manage_members?
  end

  def change_member_role?
    manage_members?
  end

  # Feature-specific permissions
  def view_agreements?
    return false unless user
    record.user_is_member?(user) || record.user_is_admin?(user)
  end

  def view_milestones?
    return false unless user
    record.user_is_member?(user) || record.user_is_admin?(user)
  end

  def view_github_logs?
    return false unless user
    record.user_is_admin?(user)
  end

  def view_time_logs?
    return false unless user
    record.user_is_member?(user) || record.user_is_admin?(user)
  end

  def view_team?
    return false unless user
    record.user_is_member?(user) || record.user_is_admin?(user)
  end

  def edit_settings?
    return false unless user
    record.user_is_admin?(user)
  end

  # Field-level authorization
  def can_view_field?(field_name)
    return false unless user

    role = record.effective_role_for(user)
    return false unless role

    visible_fields = record.fields_visible_to_role(role)
    field_name.to_s.in?(visible_fields) || visible_fields.include?("*")
  end

  class Scope < Scope
    def resolve
      if user.nil?
        # Unauthenticated users can only see publicly visible projects
        scope.publicly_visible
      else
        # Authenticated users can see:
        # 1. Their own projects
        # 2. Projects they have membership in
        # 3. Projects they have active agreements with
        # 4. Publicly visible projects (non-stealth)
        scope.left_joins(:project_memberships)
             .left_joins(agreements: :agreement_participants)
             .where(
               "projects.user_id = :user_id OR " \
               "project_memberships.user_id = :user_id OR " \
               "(agreement_participants.user_id = :user_id AND agreements.status IN (:active_statuses)) OR " \
               "projects.stealth_mode = false",
               user_id: user.id,
               active_statuses: %w[Accepted Completed]
             )
             .distinct
      end
    end
  end
end
