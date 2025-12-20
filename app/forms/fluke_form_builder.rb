# frozen_string_literal: true

class FlukeFormBuilder < ActionView::Helpers::FormBuilder
  # DaisyUI form-control wrapper
  # Usage: form.form_control(:email, label: "Email Address") { |f| f.email_field :email }
  def form_control(attribute, options = {}, &)
    label_text = options.delete(:label) || attribute.to_s.humanize
    hint = options.delete(:hint)
    required = options.delete(:required) || false
    css_class = options.delete(:class)

    @template.content_tag(:div, class: "form-control w-full #{css_class}") do
      parts = []

      # Label
      parts << @template.content_tag(:label, class: "label") do
        label_content = @template.content_tag(:span, class: "label-text") do
          required ? "#{label_text} *" : label_text
        end
        label_content
      end

      # Input (yielded content)
      parts << @template.capture(self, &)

      # Error message
      if @object&.errors&.[](attribute)&.any?
        parts << @template.content_tag(:label, class: "label") do
          @template.content_tag(:span, @object.errors[attribute].first, class: "label-text-alt text-error")
        end
      elsif hint
        parts << @template.content_tag(:label, class: "label") do
          @template.content_tag(:span, hint, class: "label-text-alt text-base-content/60")
        end
      end

      @template.safe_join(parts)
    end
  end

  # DaisyUI text input with automatic form-control wrapper
  # Usage: form.fluke_text_field :name, label: "Full Name", hint: "Enter your full name"
  def fluke_text_field(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    input_class = options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      text_field(attribute, options.merge(class: "input input-bordered w-full #{input_class}"))
    end
  end

  # DaisyUI email input
  def fluke_email_field(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    input_class = options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      email_field(attribute, options.merge(class: "input input-bordered w-full #{input_class}"))
    end
  end

  # DaisyUI password input
  def fluke_password_field(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    input_class = options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      password_field(attribute, options.merge(class: "input input-bordered w-full #{input_class}"))
    end
  end

  # DaisyUI number input
  def fluke_number_field(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    input_class = options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      number_field(attribute, options.merge(class: "input input-bordered w-full #{input_class}"))
    end
  end

  # DaisyUI date input
  def fluke_date_field(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    input_class = options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      date_field(attribute, options.merge(class: "input input-bordered w-full #{input_class}"))
    end
  end

  # DaisyUI datetime input
  def fluke_datetime_field(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    input_class = options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      datetime_local_field(attribute, options.merge(class: "input input-bordered w-full #{input_class}"))
    end
  end

  # DaisyUI textarea
  def fluke_text_area(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    textarea_class = options.delete(:class) || ""
    rows = options.delete(:rows) || 4

    form_control(attribute, wrapper_options) do |_f|
      text_area(attribute, options.merge(class: "textarea textarea-bordered w-full #{textarea_class}", rows:))
    end
  end

  # DaisyUI select
  def fluke_select(attribute, choices, options = {}, html_options = {})
    wrapper_options = extract_wrapper_options(options)
    select_class = html_options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      select(attribute, choices, options, html_options.merge(class: "select select-bordered w-full #{select_class}"))
    end
  end

  # DaisyUI file input
  def fluke_file_field(attribute, options = {})
    wrapper_options = extract_wrapper_options(options)
    input_class = options.delete(:class) || ""

    form_control(attribute, wrapper_options) do |_f|
      file_field(attribute, options.merge(class: "file-input file-input-bordered w-full #{input_class}"))
    end
  end

  # DaisyUI checkbox with label
  # Usage: form.fluke_check_box :remember_me, label: "Remember me"
  def fluke_check_box(attribute, options = {}, checked_value = "1", unchecked_value = "0")
    label_text = options.delete(:label) || attribute.to_s.humanize
    description = options.delete(:description)
    css_class = options.delete(:class) || ""

    @template.content_tag(:label, class: "flex items-start gap-3 cursor-pointer") do
      parts = []
      parts << check_box(attribute, options.merge(class: "checkbox checkbox-primary #{css_class}"), checked_value, unchecked_value)

      label_content = if description
        @template.content_tag(:div) do
          @template.safe_join([
            @template.content_tag(:span, label_text, class: "font-medium"),
            @template.content_tag(:p, description, class: "text-sm text-base-content/60")
          ])
        end
      else
        @template.content_tag(:span, label_text, class: "text-sm")
      end

      parts << label_content
      @template.safe_join(parts)
    end
  end

  # DaisyUI radio button
  # Usage: form.fluke_radio_button :payment_type, "hourly", label: "Hourly Rate"
  def fluke_radio_button(attribute, value, options = {})
    label_text = options.delete(:label) || value.to_s.humanize
    css_class = options.delete(:class) || ""

    @template.content_tag(:label, class: "flex items-center gap-3 cursor-pointer") do
      @template.safe_join([
        radio_button(attribute, value, options.merge(class: "radio radio-primary #{css_class}")),
        @template.content_tag(:span, label_text, class: "text-sm")
      ])
    end
  end

  # DaisyUI toggle/switch
  # Usage: form.fluke_toggle :notifications, label: "Enable notifications"
  def fluke_toggle(attribute, options = {})
    label_text = options.delete(:label) || attribute.to_s.humanize
    description = options.delete(:description)
    css_class = options.delete(:class) || ""

    @template.content_tag(:label, class: "flex items-start gap-3 cursor-pointer") do
      parts = []
      parts << check_box(attribute, options.merge(class: "toggle toggle-primary #{css_class}"))

      label_content = if description
        @template.content_tag(:div) do
          @template.safe_join([
            @template.content_tag(:span, label_text, class: "font-medium"),
            @template.content_tag(:p, description, class: "text-sm text-base-content/60")
          ])
        end
      else
        @template.content_tag(:span, label_text, class: "text-sm")
      end

      parts << label_content
      @template.safe_join(parts)
    end
  end

  # Enhanced submit button with automatic loading state support
  # Usage: form.submit_button "Save", loading_text: "Saving...", variant: :primary
  def submit_button(value = nil, options = {})
    value ||= submit_default_value

    # Extract custom options
    variant = options.delete(:variant) || :primary
    size = options.delete(:size) || :md
    loading_text = options.delete(:loading_text) || options.delete(:disable_with) || default_loading_text(value)
    icon = options.delete(:icon)
    skip_loading = options.delete(:skip_loading) || false
    css_class = options.delete(:class)

    # Build data attributes
    data = options.delete(:data) || {}
    unless skip_loading
      data[:"form-submission-target"] = "submit"
      data[:loading_text] = loading_text
    end

    @template.render(Ui::ButtonComponent.new(
      text: value,
      form: self,
      variant:,
      size:,
      icon:,
      css_class:,
      form_submission_target: !skip_loading,
      loading_text:,
      data:,
      **options.except(:data)
    ))
  end

  # Alias for Rails convention
  alias_method :loading_submit, :submit_button

  private

  def extract_wrapper_options(options)
    {
      label: options.delete(:label),
      hint: options.delete(:hint),
      required: options.delete(:required),
      class: options.delete(:wrapper_class)
    }
  end

  def default_loading_text(value)
    return "Processing..." if value.blank?

    # Smart defaults based on common button text
    case value.to_s.downcase
    when /creat/i then "Creating..."
    when /updat/i then "Updating..."
    when /sav/i then "Saving..."
    when /delet/i, /remov/i then "Deleting..."
    when /send/i then "Sending..."
    when /sign in/i, /log in/i then "Signing in..."
    when /sign up/i, /register/i then "Creating account..."
    when /submit/i then "Submitting..."
    when /accept/i then "Accepting..."
    when /reject/i then "Rejecting..."
    when /cancel/i then "Cancelling..."
    else "Processing..."
    end
  end
end
