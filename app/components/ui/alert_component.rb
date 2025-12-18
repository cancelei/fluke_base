# frozen_string_literal: true

module Ui
  class AlertComponent < ApplicationComponent
    VARIANTS = {
      info: {
        css: "alert-info",
        icon: "info"
      },
      warning: {
        css: "alert-warning",
        icon: "exclamation-triangle"
      },
      error: {
        css: "alert-error",
        icon: "x"
      },
      success: {
        css: "alert-success",
        icon: "check"
      }
    }.freeze

    def initialize(variant: :info, title: nil, message: nil, dismissible: false, auto_dismiss: false, auto_dismiss_delay: 5000, css_class: nil, **options)
      @variant = variant.to_sym
      @title = title
      @message = message
      @dismissible = dismissible
      @auto_dismiss = auto_dismiss
      @auto_dismiss_delay = auto_dismiss_delay
      @css_class = css_class
      @options = options
    end

    def call
      tag.div(class: combined_classes, **data_attributes, **aria_attributes) do
        safe_join([
          render_icon,
          render_content
        ].compact)
      end
    end

    private

    def variant_config
      VARIANTS[@variant] || VARIANTS[:info]
    end

    def combined_classes
      class_names(
        "alert",
        variant_config[:css],
        @css_class
      )
    end

    def data_attributes
      attrs = {}
      if @auto_dismiss
        attrs[:controller] = "auto-dismiss"
        attrs["auto-dismiss-delay-value"] = @auto_dismiss_delay
      end
      attrs
    end

    def aria_attributes
      { role: "alert" }
    end

    def render_icon
      render(Ui::IconComponent.new(
        name: variant_config[:icon],
        size: :md,
        css_class: "shrink-0"
      ))
    end

    def render_content
      if @title.present?
        tag.div do
          safe_join([
            tag.h3(@title, class: "font-bold"),
            render_message
          ].compact)
        end
      else
        render_message
      end
    end

    def render_message
      return content if content.present?
      return tag.div(@message, class: "text-sm") if @message.present?
      nil
    end
  end
end
