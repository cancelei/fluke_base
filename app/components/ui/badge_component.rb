# frozen_string_literal: true

module Ui
  class BadgeComponent < ApplicationComponent
    # DaisyUI badge variant classes
    VARIANTS = {
      primary: "badge-primary",
      secondary: "badge-neutral",
      success: "badge-success",
      warning: "badge-warning",
      danger: "badge-error",
      info: "badge-info",
      purple: "badge-secondary",
      orange: "badge-warning",
      neutral: "badge-neutral",
      accent: "badge-accent",
      ghost: "badge-ghost",
      outline: "badge-outline"
    }.freeze

    STATUS_MAPPING = {
      completed: :success,
      accepted: :success,
      active: :success,
      in_progress: :warning,
      pending: :warning,
      countered: :warning,
      rejected: :danger,
      cancelled: :danger,
      failed: :danger,
      not_started: :secondary,
      draft: :secondary
    }.freeze

    # DaisyUI badge size classes
    SIZES = {
      xs: "badge-xs",
      sm: "badge-sm",
      md: "",
      lg: "badge-lg"
    }.freeze

    def initialize(
      text:,
      variant: :primary,
      status: nil,
      size: :md,
      rounded: :full,
      css_class: nil
    )
      @text = text
      @variant = status ? status_to_variant(status) : variant.to_sym
      @size = size.to_sym
      @rounded = rounded
      @css_class = css_class
    end

    def call
      tag.span(@text, class: combined_classes)
    end

    private

    def status_to_variant(status)
      STATUS_MAPPING[status.to_s.downcase.to_sym] || :info
    end

    def combined_classes
      class_names(
        "badge",
        VARIANTS[@variant],
        SIZES[@size],
        @css_class
      )
    end
  end
end
