module ProjectsHelper
  include UiHelper

  # Determines if a project field should be displayed as public
  def field_public?(project, field_name)
    project.field_public?(field_name.to_s)
  end

  # Determines if a project field is visible to the current user
  def field_visible_to_user?(project, field_name, user)
    project.visible_to_user?(field_name.to_s, user)
  end

  # Gets the value of a project field if it's visible to the user
  def get_visible_field_value(project, field_name, user)
    project.get_field_value(field_name.to_s, user)
  end

  # Renders the appropriate field value or a restricted message
  def render_project_field(project, field_name, user)
    if field_visible_to_user?(project, field_name, user)
      value = project.send(field_name)
      value.present? ? value : "Not specified"
    else
      render_restricted_field_message
    end
  end

  # Renders a checkbox for marking a field as public
  def render_public_field_checkbox(form, field_name, project)
    content_tag(:div, class: "ml-3 flex items-center") do
      concat check_box_tag("project[public_fields][]", field_name.to_s,
                          project.field_public?(field_name.to_s),
                          id: "project_public_#{field_name}",
                          class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500")
      concat label_tag("project_public_#{field_name}", "Public", class: "ml-2 text-sm text-gray-600")
    end
  end

  # Renders field value with special formatting for certain field types
  def render_formatted_field_value(project, field_name, user)
    return render_restricted_field_message unless field_visible_to_user?(project, field_name, user)

    value = project.send(field_name)
    return "Not specified" unless value.present?

    case field_name.to_s
    when "description"
      simple_format(value)
    else
      value
    end
  end

  # Masks a project name for privacy
  def display_project_name(project, user)
    if field_visible_to_user?(project, :name, user)
      project.name
    else
      "Project ##{project.id}"
    end
  end

  # Renders a project description with privacy controls
  def display_project_description(project, user, options = {})
    if field_visible_to_user?(project, :description, user)
      description = project.description
      description = truncate(description, length: options[:length] || 100) if options[:truncate]
      content_tag(:p, description, class: options[:class])
    else
      content_tag(:p, "Available after agreement acceptance", class: options[:class])
    end
  end

  # Renders a project stage badge if visible
  def display_project_stage_badge(project, user)
    return "" unless project.stage.present? && field_visible_to_user?(project, :stage, user)
    stage_badge(project.stage)
  end

  # Renders project collaboration badges if visible
  def display_collaboration_badges(project, user)
    return "" unless project.collaboration_type.present? && field_visible_to_user?(project, :collaboration_type, user)

    content_tag(:div, class: "absolute top-0 right-0 transform translate-x-1/3 -translate-y-1/3") do
      output = "".html_safe

      if project.seeking_mentor?
        output << collaboration_badge("mentor")
      end

      if project.seeking_cofounder?
        output << " ".html_safe if project.seeking_mentor?
        output << collaboration_badge("co-founder")
      end

      output
    end
  end

  # Returns the appropriate badge class for plugin maturity level
  def badge_class_for_maturity(maturity)
    case maturity.to_s
    when "production" then "badge-success"
    when "mvp" then "badge-warning"
    when "conceptual" then "badge-neutral"
    else "badge-ghost"
    end
  end
end
