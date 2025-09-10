class ProjectVisibilityService
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
    return true if field_public?(field_name)
    return true if user && user_has_project_access?(user)
    false
  end

  def get_field_value(field_name, user)
    return nil unless field_visible_to_user?(field_name, user)
    @project.send(field_name)
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
end
