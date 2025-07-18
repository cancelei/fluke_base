module UiHelper
  def status_badge_class(status)
    case status.to_s.downcase
    when "completed", "accepted", "active"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800"
    when "in_progress", "pending", "countered"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800"
    when "rejected", "cancelled", "failed"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800"
    when "not_started", "draft"
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800"
    else
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800"
    end
  end

  def status_badge(status, text = nil)
    text ||= status.to_s.humanize
    content_tag :span, text, class: status_badge_class(status)
  end

  def render_restricted_field_message
    content_tag(:div, class: "flex items-center") do
      concat content_tag(:span, "Available after agreement acceptance", class: "text-gray-400")
      concat content_tag(:svg, tag.path(fill_rule: "evenodd", d: "M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z", clip_rule: "evenodd"), class: "ml-2 h-4 w-4 text-gray-400", fill: "currentColor", viewBox: "0 0 20 20")
    end
  end

  def icon_svg(icon_name, options = {})
    case icon_name.to_s
    when "lock"
      content_tag(:svg, tag.path(fill_rule: "evenodd", d: "M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z", clip_rule: "evenodd"),
        class: "h-4 w-4 #{options[:class]}", fill: "currentColor", viewBox: "0 0 20 20")
    else
      ""
    end
  end

  def collaboration_badge(type, text = nil)
    text ||= type.to_s.humanize
    case type.to_s.downcase
    when "mentor"
      content_tag(:span, text, class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800")
    when "co_founder", "co-founder"
      content_tag(:span, text, class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800")
    else
      content_tag(:span, text, class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800")
    end
  end

  # Enhanced Button Helper Methods
  def ui_button(text, url_or_options = {}, options = {}, &block)
    if url_or_options.is_a?(Hash)
      options = url_or_options
      url = nil
    else
      url = url_or_options
    end

    variant = options.delete(:variant) || :primary
    size = options.delete(:size) || :default
    icon = options.delete(:icon)

    css_class = "btn btn-#{variant}"
    css_class += " btn-#{size}" if size != :default
    css_class += " #{options.delete(:class)}" if options[:class]

    options[:class] = css_class

    content = []
    content << ui_icon(icon, class: "-ml-0.5 mr-1.5 h-5 w-5") if icon
    content << text

    if block_given?
      content << capture(&block)
    end

    if url
      link_to(safe_join(content), url, options)
    else
      button_to(safe_join(content), options)
    end
  end

  def ui_icon(icon_name, options = {})
    return "" if icon_name.blank?

    css_class = "h-5 w-5 #{options[:class]}"

    case icon_name.to_s
    when "plus"
      content_tag(:svg,
        tag.path(fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z", clip_rule: "evenodd"),
        class: css_class, fill: "currentColor", viewBox: "0 0 20 20")
    when "edit"
      content_tag(:svg,
        tag.path(d: "M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"),
        class: css_class, fill: "currentColor", viewBox: "0 0 20 20")
    when "trash"
      content_tag(:svg,
        tag.path(fill_rule: "evenodd", d: "M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z", clip_rule: "evenodd"),
        class: css_class, fill: "currentColor", viewBox: "0 0 20 20")
    when "eye"
      content_tag(:svg,
        tag.path(d: "M10 12a2 2 0 100-4 2 2 0 000 4z") +
        tag.path(fill_rule: "evenodd", d: "M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z", clip_rule: "evenodd"),
        class: css_class, fill: "currentColor", viewBox: "0 0 20 20")
    when "message"
      content_tag(:svg,
        tag.path(d: "M2 5a2 2 0 012-2h7a2 2 0 012 2v4a2 2 0 01-2 2H9l-3 3v-3H4a2 2 0 01-2-2V5z") +
        tag.path(d: "M15 7v2a4 4 0 01-4 4H9.828l-1.766 1.767c.28.149.599.233.938.233h2l3 3v-3h2a2 2 0 002-2V9a2 2 0 00-2-2h-1z"),
        class: css_class, fill: "currentColor", viewBox: "0 0 20 20")
    when "lock"
      content_tag(:svg,
        tag.path(fill_rule: "evenodd", d: "M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z", clip_rule: "evenodd"),
        class: css_class, fill: "currentColor", viewBox: "0 0 20 20")
    when "github"
      content_tag(:svg,
        tag.path(fill_rule: "evenodd", d: "M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.1-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z", clip_rule: "evenodd"),
        class: css_class, fill: "currentColor", viewBox: "0 0 24 24")
    when "exclamation-triangle"
      content_tag(:svg,
        tag.path(fill_rule: "evenodd", d: "M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z", clip_rule: "evenodd"),
        class: css_class, fill: "currentColor", viewBox: "0 0 20 20")
    else
      ""
    end
  end

  def ui_badge(text, variant = :primary, options = {})
    css_class = "badge badge-#{variant}"
    css_class += " #{options[:class]}" if options[:class]

    content_tag(:span, text, class: css_class)
  end

  def ui_card(options = {}, &block)
    css_class = "card"
    css_class += " #{options[:class]}" if options[:class]

    content_tag(:div, class: css_class, &block)
  end

  def ui_card_header(title, subtitle = nil, options = {})
    css_class = "card-header"
    css_class += " #{options[:class]}" if options[:class]

    content_tag(:div, class: css_class) do
      content = []
      content << content_tag(:h3, title, class: "text-lg font-medium leading-6 text-gray-900")
      content << content_tag(:p, subtitle, class: "mt-1 max-w-2xl text-sm text-gray-500") if subtitle
      safe_join(content)
    end
  end

  def ui_empty_state(title, description, action_text = nil, action_url = nil, options = {})
    content_tag(:div, class: "text-center py-12") do
      content = []

      # Icon
      icon = options[:icon] || "folder"
      content << content_tag(:div, class: "mx-auto h-12 w-12 text-gray-400") do
        ui_icon(icon, class: "mx-auto h-12 w-12")
      end

      # Title
      content << content_tag(:h3, title, class: "mt-2 text-sm font-medium text-gray-900")

      # Description
      content << content_tag(:p, description, class: "mt-1 text-sm text-gray-500")

      # Action button
      if action_text && action_url
        content << content_tag(:div, class: "mt-6") do
          ui_button(action_text, action_url, variant: :primary, icon: "plus")
        end
      end

      safe_join(content)
    end
  end

  def ui_search_form(url, options = {}, &block)
    search_value = options[:search_value] || params[:search]
    method = options[:method] || :get

    form_with(url: url, method: method, class: "flex space-x-2") do |f|
      content = []

      # Search input
      content << f.text_field(:search,
        value: search_value,
        placeholder: options[:placeholder] || "Search...",
        class: "form-input")

      # Additional form fields from block
      if block_given?
        content << capture(f, &block)
      end

      # Submit button
      content << f.submit(options[:submit_text] || "Search", class: "btn btn-primary")

      safe_join(content)
    end
  end

  # User Card Helper Methods
  def user_card_color_scheme(role)
    case role
    when Role::MENTOR
      {
        container: "border-blue-200",
        avatar_bg: "bg-blue-50",
        avatar_icon: "text-blue-300",
        role_badge: "bg-blue-100 text-blue-700",
        footer_border: "border-blue-100",
        footer_text: "text-blue-600 group-hover:text-blue-800",
        message_btn: "text-blue-700 ring-blue-200 hover:bg-blue-50"
      }
    when Role::ENTREPRENEUR
      {
        container: "border-green-200",
        avatar_bg: "bg-green-50",
        avatar_icon: "text-green-300",
        role_badge: "bg-green-100 text-green-700",
        footer_border: "border-green-100",
        footer_text: "text-green-600 group-hover:text-green-800",
        message_btn: "text-green-700 ring-green-200 hover:bg-green-50"
      }
    else
      {
        container: "border-gray-200",
        avatar_bg: "bg-indigo-100",
        avatar_icon: "text-indigo-300",
        role_badge: "bg-indigo-100 text-indigo-700",
        footer_border: "border-gray-200",
        footer_text: "text-indigo-600 group-hover:text-indigo-800",
        message_btn: "text-gray-700 ring-gray-200 hover:bg-gray-50"
      }
    end
  end

  def default_bio_for_role(role)
    case role
    when Role::MENTOR
      "Experienced professional ready to mentor"
    when Role::ENTREPRENEUR
      "Aspiring entrepreneur building the future"
    else
      "Member of the FlukeBase community"
    end
  end

  def render_role_specific_content(user, role)
    case role
    when Role::MENTOR
      render_mentor_card_content(user)
    when Role::ENTREPRENEUR
      render_entrepreneur_card_content(user)
    else
      render_general_card_content(user)
    end
  end

  def render_mentor_card_content(user)
    content = []

    # Skills
    skills = user.skills || [ "Business", "Tech", "Marketing", "UI/UX", "Growth" ]
    content << content_tag(:div, class: "flex flex-wrap gap-1") do
      skills.first(3).map do |skill|
        content_tag(:span, skill, class: "inline-flex items-center rounded bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700")
      end.join.html_safe
    end

    # Stats
    content << content_tag(:div, class: "mt-2 flex justify-between items-center text-xs text-gray-600") do
      "Mentees: #{user.other_party_agreements.completed.count}"
    end

    safe_join(content)
  end

  def render_entrepreneur_card_content(user)
    content = []

    content << content_tag(:div, class: "flex flex-col gap-1 text-xs text-gray-600") do
      stats = []
      stats << "Projects: <strong>#{user.projects.count}</strong>"
      if user.projects.any? && user.projects.first.stage.present?
        stats << "Stage: #{user.projects.first.stage.capitalize}"
      end
      safe_join(stats.map { |stat| content_tag(:span, stat.html_safe) })
    end

    safe_join(content)
  end

  def render_general_card_content(user)
    content = []

    content << content_tag(:div, class: "text-xs text-gray-600") do
      "Active Projects: #{user.my_agreements.where(status: Agreement::ACCEPTED).count}"
    end

    content << content_tag(:div, class: "mt-2") do
      render partial: "shared/achievements", locals: { user: user, user_role: :entrepreneur }
    end

    safe_join(content)
  end
end

def stage_badge(stage)
  return "" unless stage.present?

  content_tag(:span, stage.capitalize,
    class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800")
end
