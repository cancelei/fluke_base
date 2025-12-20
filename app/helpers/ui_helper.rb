module UiHelper
  def status_badge(status, text = nil)
    text ||= status.to_s.humanize
    render(Ui::BadgeComponent.new(text:, status: status.to_s))
  end

  def kpi_badge_class(status)
    Ui::SharedConstants.kpi_badge_class(status)
  end

  def render_restricted_field_message
    content_tag(:div, class: "flex items-center") do
      concat content_tag(:span, "Available after agreement acceptance", class: "text-gray-400")
      concat render(Ui::IconComponent.new(name: :lock, size: :sm, css_class: "ml-2 text-gray-400"))
    end
  end

  def collaboration_badge(type, text = nil)
    text ||= type.to_s.humanize
    variant = case type.to_s.downcase
    when "mentor" then :success
    when "co_founder", "co-founder" then :purple
    else :info
    end
    render(Ui::BadgeComponent.new(text:, variant:, rounded: :default, size: :sm))
  end

  def ui_button(text, url_or_options = {}, options = {}, &)
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
      text:,
      url:,
      variant:,
      size:,
      icon:,
      method:,
      data:,
      css_class:,
      **options
    )) do
      block_given? ? capture(&) : nil
    end
  end

  def ui_icon(icon_name, options = {})
    return "" if icon_name.blank?
    size = options.fetch(:size, :md)
    render(Ui::IconComponent.new(name: icon_name, size:, css_class: options[:class]))
  end

  def ui_badge(text, variant = :primary, options = {})
    render(Ui::BadgeComponent.new(text:, variant:, css_class: options[:class]))
  end

  def ui_alert(variant: :info, title: nil, message: nil, **, &)
    render(Ui::AlertComponent.new(variant:, title:, message:, **), &)
  end

  def ui_card(options = {}, &)
    variant = options.delete(:variant) || :default
    css_class = options.delete(:class)
    render(Ui::CardComponent.new(variant:, css_class:, **options), &)
  end

  def ui_card_header(title, subtitle = nil, options = {})
    css_class = options.delete(:class)
    content_tag(:div, class: "px-6 py-4 border-b border-base-200 bg-base-200/30 #{css_class}") do
      content = []
      content << content_tag(:h3, title, class: "card-title text-lg font-semibold")
      content << content_tag(:p, subtitle, class: "mt-1 text-sm opacity-70") if subtitle
      safe_join(content)
    end
  end

  def ui_empty_state(title, description, action_text = nil, action_url = nil, options = {})
    icon = options.delete(:icon) || :folder
    css_class = options.delete(:class)
    render(Ui::EmptyStateComponent.new(
      title:,
      description:,
      icon:,
      action_text:,
      action_url:,
      css_class:
    ))
  end

  def ui_search_form(url, options = {}, &)
    search_value = options[:search_value] || params[:search]
    method = options[:method] || :get

    form_with(url:, method:, class: "flex space-x-2") do |f|
      content = []
      content << f.text_field(:search,
        value: search_value,
        placeholder: options[:placeholder] || "Search...",
        class: "form-input")
      content << capture(f, &) if block_given?
      content << f.submit(options[:submit_text] || "Search", class: "btn btn-primary")
      safe_join(content)
    end
  end

  def stage_badge(stage)
    return "" unless stage.present?
    render(Ui::BadgeComponent.new(text: stage.capitalize, variant: :info))
  end

  def fluke_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &)
    html_options = options.delete(:html) || {}
    data = html_options[:data] || options.delete(:data) || {}

    unless options.delete(:skip_loading_states)
      existing_controller = data[:controller]
      data[:controller] = [existing_controller, "form-submission"].compact.join(" ")
      existing_action = data[:action]
      data[:action] = [existing_action, "submit->form-submission#submit"].compact.join(" ")
    end

    html_options[:data] = data

    form_with(
      model:,
      scope:,
      url:,
      format:,
      builder: FlukeFormBuilder,
      **options.merge(html: html_options),
      &
    )
  end

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
      text:,
      type: "submit",
      variant:,
      size:,
      icon:,
      css_class:,
      disabled:,
      form_submission_target: true,
      loading_text:,
      data:
    ))
  end

  def ui_button_to(text, url, options = {})
    variant = options.delete(:variant) || :primary
    size = options.delete(:size) || :md
    loading_text = options.delete(:loading_text)
    icon = options.delete(:icon)
    css_class = options.delete(:class)
    method = options.delete(:method)
    confirm = options.delete(:confirm)

    button_classes = class_names(
      "btn",
      Ui::ButtonComponent::VARIANTS[variant.to_sym],
      Ui::ButtonComponent::SIZES[size.to_sym],
      css_class
    )

    data = options.delete(:data) || {}
    data[:turbo_confirm] = confirm if confirm

    form_data = options.delete(:form) || {}
    if loading_text
      form_data[:controller] ||= "form-submission"
      form_data[:action] ||= "submit->form-submission#submit"
    end

    button_data = {}
    if loading_text
      button_data[:"form-submission-target"] = "submit"
      button_data[:loading_text] = loading_text
    end

    button_to(
      url,
      method:,
      class: button_classes,
      data: data.merge(button_data),
      form: form_data.present? ? { data: form_data } : {},
      **options
    ) do
      button_content_for(text, icon)
    end
  end

  def ui_modal(id:, title: nil, size: :md, position: :middle, closeable: true, close_button_text: "Close", classes: "", &)
    render(Ui::ModalComponent.new(
      id:,
      title:,
      size:,
      position:,
      closeable:,
      close_button_text:,
      classes:
    ), &)
  end

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
