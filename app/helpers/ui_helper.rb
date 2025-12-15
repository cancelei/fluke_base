module UiHelper
  # Delegate to BadgeComponent for status badges
  def status_badge(status, text = nil)
    text ||= status.to_s.humanize
    render(Ui::BadgeComponent.new(text: text, status: status.to_s))
  end

  # Legacy method kept for backwards compatibility - returns CSS class string
  # Prefer using status_badge helper or Ui::BadgeComponent directly
  def status_badge_class(status)
    variant = Ui::BadgeComponent::STATUS_MAPPING[status.to_s.downcase.to_sym] || :info
    variant_class = Ui::BadgeComponent::VARIANTS[variant]
    "badge #{variant_class}"
  end

  # Returns DaisyUI badge class for KPI/performance status indicators
  # Used in agreement KPIs, time tracking analytics, and performance views
  # @param status [String, Symbol] The KPI status (excellent, good, on_track, fair, poor, etc.)
  # @return [String] DaisyUI badge class (e.g., "badge-success", "badge-warning")
  def kpi_badge_class(status)
    Ui::SharedConstants.kpi_badge_class(status)
  end

  # Render restricted field message with lock icon
  def render_restricted_field_message
    content_tag(:div, class: "flex items-center") do
      concat content_tag(:span, "Available after agreement acceptance", class: "text-gray-400")
      concat render(Ui::IconComponent.new(name: :lock, size: :sm, css_class: "ml-2 text-gray-400"))
    end
  end

  # Delegate to BadgeComponent
  # Collaboration type badges with type-specific variants
  def collaboration_badge(type, text = nil)
    text ||= type.to_s.humanize
    variant = case type.to_s.downcase
    when "mentor" then :success
    when "co_founder", "co-founder" then :purple
    else :info
    end
    render(Ui::BadgeComponent.new(text: text, variant: variant, rounded: :default, size: :sm))
  end

  # Delegate to ButtonComponent
  # Enhanced Button Helper Methods
  def ui_button(text, url_or_options = {}, options = {}, &block)
    if url_or_options.is_a?(Hash)
      options = url_or_options
      url = nil
    else
      url = url_or_options
    end

    variant = options.delete(:variant) || :primary
    size = options.delete(:size) || :md
    size = :md if size == :default
    icon = options.delete(:icon)
    css_class = options.delete(:class)
    method = options.delete(:method)
    data = options.delete(:data) || {}

    render(Ui::ButtonComponent.new(
      text: text,
      url: url,
      variant: variant,
      size: size,
      icon: icon,
      method: method,
      data: data,
      css_class: css_class,
      **options
    )) do
      block_given? ? capture(&block) : nil
    end
  end

  # Delegate to IconComponent
  def ui_icon(icon_name, options = {})
    return "" if icon_name.blank?
    render(Ui::IconComponent.new(name: icon_name, size: :md, css_class: options[:class]))
  end

  # Delegate to BadgeComponent
  def ui_badge(text, variant = :primary, options = {})
    render(Ui::BadgeComponent.new(text: text, variant: variant, css_class: options[:class]))
  end

  # Delegate to CardComponent
  # Note: For full CardComponent features (header/footer slots), use the component directly
  def ui_card(options = {}, &block)
    variant = options.delete(:variant) || :default
    css_class = options.delete(:class)
    render(Ui::CardComponent.new(variant: variant, css_class: css_class, **options), &block)
  end

  # Render a card header - for simple use cases
  # For complex headers, use CardComponent with header slot directly
  def ui_card_header(title, subtitle = nil, options = {})
    css_class = options.delete(:class)
    content_tag(:div, class: "px-6 py-4 border-b border-base-200 bg-base-200/30 #{css_class}") do
      content = []
      content << content_tag(:h3, title, class: "card-title text-lg font-semibold")
      content << content_tag(:p, subtitle, class: "mt-1 text-sm opacity-70") if subtitle
      safe_join(content)
    end
  end

  # Delegate to EmptyStateComponent
  def ui_empty_state(title, description, action_text = nil, action_url = nil, options = {})
    icon = options.delete(:icon) || :folder
    css_class = options.delete(:class)
    render(Ui::EmptyStateComponent.new(
      title: title,
      description: description,
      icon: icon,
      action_text: action_text,
      action_url: action_url,
      css_class: css_class
    ))
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

  # Delegate to BadgeComponent
  def stage_badge(stage)
    return "" unless stage.present?
    render(Ui::BadgeComponent.new(text: stage.capitalize, variant: :info))
  end

  # Form helper that auto-attaches form-submission controller for loading states
  # Usage: fluke_form_with(model: @project) do |f| ... end
  def fluke_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
    html_options = options.delete(:html) || {}
    data = html_options[:data] || options.delete(:data) || {}

    # Auto-attach form-submission controller unless opted out
    unless options.delete(:skip_loading_states)
      existing_controller = data[:controller]
      data[:controller] = [ existing_controller, "form-submission" ].compact.join(" ")
      existing_action = data[:action]
      data[:action] = [ existing_action, "submit->form-submission#submit" ].compact.join(" ")
    end

    html_options[:data] = data

    form_with(
      model: model,
      scope: scope,
      url: url,
      format: format,
      builder: FlukeFormBuilder,
      **options.merge(html: html_options),
      &block
    )
  end

  # Submit button helper for use outside of fluke_form_with
  # Usage: ui_submit_button("Save", variant: :primary, loading_text: "Saving...")
  def ui_submit_button(text, options = {})
    variant = options.delete(:variant) || :primary
    size = options.delete(:size) || :md
    loading_text = options.delete(:loading_text) || "Processing..."
    icon = options.delete(:icon)
    css_class = options.delete(:class)
    disabled = options.delete(:disabled) || false

    data = options.delete(:data) || {}
    data[:"form-submission-target"] = "submit"
    data[:loading_text] = loading_text

    render(Ui::ButtonComponent.new(
      text: text,
      type: "submit",
      variant: variant,
      size: size,
      icon: icon,
      css_class: css_class,
      disabled: disabled,
      form_submission_target: true,
      loading_text: loading_text,
      data: data
    ))
  end

  # Enhanced button_to with DaisyUI styling and loading states
  # Usage: ui_button_to("Delete", item_path(item), method: :delete, variant: :danger)
  def ui_button_to(text, url, options = {})
    variant = options.delete(:variant) || :primary
    size = options.delete(:size) || :md
    loading_text = options.delete(:loading_text)
    icon = options.delete(:icon)
    css_class = options.delete(:class)
    method = options.delete(:method)
    confirm = options.delete(:confirm)

    # Build button classes
    button_classes = class_names(
      "btn",
      Ui::ButtonComponent::VARIANTS[variant.to_sym],
      Ui::ButtonComponent::SIZES[size.to_sym],
      css_class
    )

    # Build data attributes
    data = options.delete(:data) || {}
    data[:turbo_confirm] = confirm if confirm

    # Form wrapper data for loading states
    form_data = options.delete(:form) || {}
    if loading_text
      form_data[:controller] ||= "form-submission"
      form_data[:action] ||= "submit->form-submission#submit"
    end

    # Button data attributes
    button_data = {}
    if loading_text
      button_data[:"form-submission-target"] = "submit"
      button_data[:loading_text] = loading_text
    end

    button_to(
      url,
      method: method,
      class: button_classes,
      data: data.merge(button_data),
      form: form_data.present? ? { data: form_data } : {},
      **options
    ) do
      button_content_for(text, icon)
    end
  end

  # Render a modal dialog with content
  # Usage:
  #   ui_modal(id: "confirm-modal", title: "Confirm") do
  #     <p>Are you sure?</p>
  #   end
  def ui_modal(id:, title: nil, size: :md, position: :middle, closeable: true, close_button_text: "Close", classes: "", &block)
    render(Ui::ModalComponent.new(
      id: id,
      title: title,
      size: size,
      position: position,
      closeable: closeable,
      close_button_text: close_button_text,
      classes: classes
    ), &block)
  end

  # Render a button that opens a modal
  # Usage: ui_modal_trigger("Open Modal", modal_id: "my-modal", variant: :primary)
  def ui_modal_trigger(text, modal_id:, variant: :primary, size: :md, icon: nil, css_class: nil)
    button_tag(
      type: "button",
      class: class_names(
        "btn",
        Ui::ButtonComponent::VARIANTS[variant.to_sym],
        Ui::ButtonComponent::SIZES[size.to_sym],
        css_class
      ),
      onclick: "document.getElementById('#{modal_id}').showModal()"
    ) do
      if icon
        safe_join([
          render(Ui::IconComponent.new(name: icon, size: :sm, css_class: "-ml-0.5 mr-1.5")),
          text
        ])
      else
        text
      end
    end
  end

  private

  def button_content_for(text, icon)
    if icon
      safe_join([
        render(Ui::IconComponent.new(name: icon, size: :sm, css_class: "-ml-0.5 mr-1.5")),
        text
      ])
    else
      text
    end
  end
end
