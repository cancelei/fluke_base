# frozen_string_literal: true

# Service for checking project visibility and field access
# Query service - returns direct values (no Result types needed for queries)
class ProjectVisibilityService < ApplicationService
  def initialize(project)
    @project = project
    @user_access_cache = {}
  end

  def field_public?(field_name)
    return false unless @project.public_fields.is_a?(Array)
    @project.public_fields.include?(field_name.to_s)
  end

  def field_visible_to_user?(field_name, user)
    return true if user && (@project.user_id == user.id)
    return true if field_public?(field_name) && !@project.stealth?
    return true if user && user_has_project_access?(user)
    return false if @project.stealth? && !user_has_stealth_access?(user)
    false
  end

  def get_field_value(field_name, user)
    return nil unless field_visible_to_user?(field_name, user)

    # For stealth projects, return stealth display values for unauthorized users
    if @project.stealth? && !user_has_stealth_access?(user)
      return stealth_field_value(field_name)
    end

    @project.send(field_name)
  end

  def stealth_visible_to_user?(user)
    return true if user && (@project.user_id == user.id)
    return true if user && user_has_project_access?(user)
    false
  end

  # Batch check access for multiple users to reduce N+1 queries
  def self.batch_check_access(projects, users)
    project_ids = projects.map(&:id)
    user_ids = users.map(&:id)

    # Get all agreements for these projects and users in one query
    access_map = Agreement.joins(:agreement_participants)
                         .where(project_id: project_ids, agreement_participants: { user_id: user_ids })
                         .pluck(:project_id, "agreement_participants.user_id")
                         .group_by { |project_id, user_id| project_id }
                         .transform_values { |pairs| pairs.map(&:second) }

    access_map
  end

  private

  def user_has_project_access?(user)
    return false unless user

    # Cache the result to avoid repeated queries
    @user_access_cache[user.id] ||= @project.agreements
                                           .joins(:agreement_participants)
                                           .exists?(agreement_participants: { user_id: user.id })
  end

  def user_has_stealth_access?(user)
    return false unless user
    return true if @project.user_id == user.id
    user_has_project_access?(user)
  end

  def stealth_field_value(field_name)
    case field_name.to_s
    when "name"
      @project.stealth_display_name
    when "description"
      @project.stealth_display_description
    when "category"
      @project.stealth_category.presence || "Technology"
    else
      nil  # Other fields hidden for unauthorized users
    end
  end
end
