class ProjectVisibilityService
  def initialize(project)
    @project = project
  end

  def field_public?(field_name)
    return false unless @project.public_fields.is_a?(Array)
    @project.public_fields.include?(field_name.to_s)
  end

  def field_visible_to_user?(field_name, user)
    return true if user && (@project.user_id == user.id)
    return true if field_public?(field_name)
    return true if user && @project.agreements.exists?(other_party_id: user.id)
    false
  end

  def get_field_value(field_name, user)
    return nil unless field_visible_to_user?(field_name, user)
    @project.send(field_name)
  end
end
