# frozen_string_literal: true

module Project::AccessControl
  extend ActiveSupport::Concern

  included do
    # Any specific associations or logic for the concern can go here
  end

  # Find membership for a specific user
  # @param user [User] The user to find membership for
  # @return [ProjectMembership, nil] The membership record or nil
  def membership_for(user)
    return nil unless user
    project_memberships.find_by(user_id: user.id)
  end

  # Get the role for a specific user
  # @param user [User] The user to get role for
  # @return [String, nil] The role name or nil if no membership
  def role_for(user) = membership_for(user)&.role

  # Check if user is the project owner (original owner or owner role)
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_owner?(user)
    return false unless user
    user_id == user.id || membership_for(user)&.owner?
  end

  # Check if user has admin or higher access
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_admin?(user)
    return false unless user
    user_is_owner?(user) || membership_for(user)&.admin?
  end

  # Check if user has member or higher access
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_member?(user)
    return false unless user
    membership = membership_for(user)
    membership&.member? || has_active_agreement_with?(user)
  end

  # Check if user is a guest
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_guest?(user)
    return false unless user
    membership_for(user)&.guest?
  end

  # Check if user has any access to the project
  # @param user [User] The user to check
  # @return [Boolean]
  def user_has_access?(user)
    return false unless user
    membership_for(user).present? || has_active_agreement_with?(user)
  end

  # Check if user has an active agreement with this project
  # @param user [User] The user to check
  # @return [Boolean]
  def has_active_agreement_with?(user)
    return false unless user
    agreements.joins(:agreement_participants)
              .where(agreement_participants: { user_id: user.id })
              .where(status: %w[Accepted Completed])
              .exists?
  end

  # Get fields visible to a specific role
  # @param role [String] The role to check
  # @return [Array<String>] List of visible field names
  def fields_visible_to_role(role)
    case role.to_s
    when "owner"
      # Owners see everything
      Project::PUBLIC_FIELD_OPTIONS + %w[repository_url stealth_name stealth_description stealth_category milestones agreements time_logs github_logs]
    when "admin"
      # Admins see most fields plus internal data
      Project::PUBLIC_FIELD_OPTIONS + %w[milestones agreements time_logs]
    when "member"
      # Members see public fields plus shared project info
      (public_fields || Project::DEFAULT_PUBLIC_FIELDS)
    when "guest"
      # Guests see only explicitly public fields, respecting stealth mode
      return [] if stealth?
      (public_fields || []).select { |f| f.in?(%w[name category stage]) }
    else
      []
    end
  end

  # Determine effective role for a user (considers agreements too)
  # @param user [User] The user to check
  # @return [String, nil] The effective role
  def effective_role_for(user)
    return nil unless user

    # Check if user is the original owner
    return "owner" if user_id == user.id

    # Check explicit membership
    membership = membership_for(user)
    return membership.role if membership

    # Check if user has access via agreements
    return "member" if has_active_agreement_with?(user)

    # Check if project is publicly discoverable
    return "guest" if publicly_discoverable?

    nil
  end
end
