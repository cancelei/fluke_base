module ProjectsHelper
  # Determines if a project field should be displayed as public
  # @param project [Project] the project object
  # @param field_name [String, Symbol] the name of the field to check
  # @return [Boolean] whether the field is marked as public
  def field_public?(project, field_name)
    project.field_public?(field_name.to_s)
  end

  # Determines if a project field is visible to the current user
  # @param project [Project] the project object
  # @param field_name [String, Symbol] the name of the field to check
  # @param user [User] the user to check visibility for
  # @return [Boolean] whether the field is visible to the user
  def field_visible_to_user?(project, field_name, user)
    project.visible_to_user?(field_name.to_s, user)
  end

  # Gets the value of a project field if it's visible to the user, otherwise returns nil
  # @param project [Project] the project object
  # @param field_name [String, Symbol] the name of the field to retrieve
  # @param user [User] the user to check visibility for
  # @return [Object, nil] the field value if visible, nil otherwise
  def get_visible_field_value(project, field_name, user)
    project.get_field_value(field_name.to_s, user)
  end

  # Renders the appropriate field value or a restricted message
  # @param project [Project] the project object
  # @param field_name [String, Symbol] the name of the field to display
  # @param user [User] the current user
  # @return [String] HTML to display for the field
  def render_project_field(project, field_name, user)
    if field_visible_to_user?(project, field_name, user)
      value = project.send(field_name)
      value.present? ? value : "Not specified"
    else
      render_restricted_field_message
    end
  end

  # Renders the message for a restricted field
  # @return [String] HTML for the restricted field message
  def render_restricted_field_message
    content_tag(:div, class: "flex items-center") do
      concat content_tag(:span, "Available after agreement acceptance", class: "text-gray-400")
      concat content_tag(:svg, tag.path(fill_rule: "evenodd", d: "M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z", clip_rule: "evenodd"), class: "ml-2 h-4 w-4 text-gray-400", fill: "currentColor", viewBox: "0 0 20 20")
    end
  end

  # Renders a checkbox for marking a field as public
  # @param form [FormBuilder] the form builder object
  # @param field_name [String, Symbol] the name of the field
  # @param project [Project] the project object
  # @return [String] HTML for the public checkbox
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
  # @param project [Project] the project object
  # @param field_name [String, Symbol] the name of the field to display
  # @param user [User] the current user
  # @return [String] HTML for the formatted field value
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
  # @param project [Project] the project object
  # @param user [User] the current user viewing the project
  # @return [String] visible name or masked ID
  def display_project_name(project, user)
    if field_visible_to_user?(project, :name, user)
      project.name
    else
      "Project ##{project.id}"
    end
  end

  # Renders a project description with privacy controls
  # @param project [Project] the project object
  # @param user [User] the current user viewing the project
  # @param options [Hash] additional options (truncate, classes, etc.)
  # @return [String] HTML for the description
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
  # @param project [Project] the project object
  # @param user [User] the current user viewing the project
  # @return [String] HTML for the stage badge or empty string if not visible
  def display_project_stage_badge(project, user)
    return "" unless project.stage.present? && field_visible_to_user?(project, :stage, user)

    content_tag(:span, project.stage.capitalize,
      class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800")
  end

  # Renders project collaboration badges if visible
  # @param project [Project] the project object
  # @param user [User] the current user viewing the project
  # @return [String] HTML for the collaboration badges or empty string if not visible
  def display_collaboration_badges(project, user)
    return "" unless project.collaboration_type.present? && field_visible_to_user?(project, :collaboration_type, user)

    content_tag(:div, class: "absolute top-0 right-0 transform translate-x-1/3 -translate-y-1/3") do
      output = "".html_safe

      if project.seeking_mentor?
        output << content_tag(:span, "Mentor",
          class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800")
      end

      if project.seeking_cofounder?
        output << " ".html_safe if project.seeking_mentor?
        output << content_tag(:span, "Co-Founder",
          class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800")
      end

      output
    end
  end
end
