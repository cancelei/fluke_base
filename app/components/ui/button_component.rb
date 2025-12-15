# frozen_string_literal: true

module Ui
  class ButtonComponent < ApplicationComponent
    # DaisyUI button variant classes
    VARIANTS = {
      primary: "btn-primary",
      secondary: "btn-ghost",
      success: "btn-success",
      danger: "btn-error",
      warning: "btn-warning",
      info: "btn-info",
      ghost: "btn-ghost",
      outline: "btn-outline",
      neutral: "btn-neutral",
      accent: "btn-accent"
    }.freeze

    # DaisyUI button size classes
    SIZES = {
      xs: "btn-xs",
      sm: "btn-sm",
      md: "",
      lg: "btn-lg"
    }.freeze

    # DaisyUI spinner sizes mapped to button sizes
    SPINNER_SIZES = {
      xs: "loading-xs",
      sm: "loading-xs",
      md: "loading-sm",
      lg: "loading-md"
    }.freeze

    def initialize(
      text: nil,
      url: nil,
      variant: :primary,
      size: :md,
      icon: nil,
      icon_position: :left,
      disabled: false,
      method: nil,
      data: {},
      css_class: nil,
      form: nil,
      type: "button",
      # Loading state options
      loading: false,
      loading_text: nil,
      disable_with: nil,
      form_submission_target: false,
      **options
    )
      @text = text
      @url = url
      @variant = variant.to_sym
      @size = size.to_sym
      @icon = icon
      @icon_position = icon_position
      @disabled = disabled
      @method = method
      @data = data
      @css_class = css_class
      @form = form
      @type = type
      @loading = loading
      @loading_text = loading_text || disable_with
      @form_submission_target = form_submission_target
      @options = options
    end

    def call
      if @url
        render_link
      elsif @form
        render_submit
      else
        render_button
      end
    end

    private

    def render_link
      link_to(@url, class: combined_classes, data: combined_data, **link_options) do
        button_content
      end
    end

    def render_submit
      @form.submit(@text, class: combined_classes, disabled: @disabled, data: submit_data_attributes)
    end

    def render_button
      tag.button(
        class: combined_classes,
        disabled: @disabled || @loading,
        data: combined_data,
        type: @type,
        **@options
      ) do
        @loading ? loading_content : button_content
      end
    end

    def button_content
      parts = []
      parts << render_icon(:left) if @icon && @icon_position == :left
      parts << @text if @text
      parts << content if content?
      parts << render_icon(:right) if @icon && @icon_position == :right
      safe_join(parts)
    end

    def loading_content
      parts = []
      parts << tag.span(class: "loading loading-spinner #{SPINNER_SIZES[@size]}")
      parts << tag.span(@loading_text || @text || "Processing...", class: "ml-2")
      safe_join(parts)
    end

    def render_icon(position)
      margin = position == :left ? "-ml-0.5 mr-1.5" : "ml-1.5 -mr-0.5"
      render(Ui::IconComponent.new(name: @icon, size: icon_size, css_class: margin))
    end

    def icon_size
      case @size
      when :sm then :xs
      when :lg then :md
      else :sm
      end
    end

    def combined_classes
      class_names(
        "btn",
        VARIANTS[@variant],
        SIZES[@size],
        disabled_class,
        loading_class,
        @css_class
      )
    end

    def disabled_class
      "btn-disabled" if @disabled
    end

    def loading_class
      "opacity-75 cursor-not-allowed" if @loading
    end

    def combined_data
      data = @data.dup
      data[:turbo_method] = @method if @method
      data[:"form-submission-target"] = "submit" if @form_submission_target
      data[:loading_text] = @loading_text if @loading_text
      data
    end

    def submit_data_attributes
      data = @data.dup
      data[:"form-submission-target"] = "submit" if @form_submission_target
      data[:loading_text] = @loading_text if @loading_text
      data
    end

    def link_options
      opts = {}
      opts[:method] = @method if @method && !@data[:turbo_method]
      opts
    end
  end
end
