# frozen_string_literal: true

module Ui
  class AvatarComponent < ApplicationComponent
    SIZES = {
      xs: { container: "w-6 h-6", icon: "h-3 w-3", text: "text-xs" },
      sm: { container: "w-8 h-8", icon: "h-4 w-4", text: "text-xs" },
      md: { container: "w-12 h-12", icon: "h-6 w-6", text: "text-sm" },
      lg: { container: "w-16 h-16", icon: "h-8 w-8", text: "text-base" },
      xl: { container: "w-24 h-24", icon: "h-12 w-12", text: "text-xl" },
      xxl: { container: "w-32 h-32", icon: "h-16 w-16", text: "text-2xl" }
    }.freeze

    PLACEHOLDER_STYLES = {
      icon: :render_icon_placeholder,
      initials: :render_initials_placeholder
    }.freeze

    def initialize(user:, size: :md, ring: false, ring_color: "primary", placeholder: :icon, css_class: nil)
      @user = user
      @size = size.to_sym
      @ring = ring
      @ring_color = ring_color
      @placeholder = placeholder.to_sym
      @css_class = css_class
    end

    def call
      if avatar_attached?
        render_image_avatar
      else
        render_placeholder_avatar
      end
    end

    def render?
      @user.present?
    end

    private

    def avatar_attached?
      @user.respond_to?(:avatar) && @user.avatar.attached?
    end

    def size_config
      SIZES[@size] || SIZES[:md]
    end

    def ring_classes
      return "" unless @ring

      "ring ring-#{@ring_color} ring-offset-base-100 ring-offset-2"
    end

    def render_image_avatar
      tag.div(class: "avatar") do
        tag.div(class: class_names(size_config[:container], "rounded-full", ring_classes, @css_class)) do
          helpers.image_tag(@user.avatar, alt: user_initials, class: "object-cover rounded-full")
        end
      end
    end

    def render_placeholder_avatar
      tag.div(class: "avatar placeholder") do
        tag.div(
          class: class_names(
            "bg-primary text-primary-content rounded-full flex items-center justify-center",
            size_config[:container],
            ring_classes,
            @css_class
          )
        ) do
          send(PLACEHOLDER_STYLES[@placeholder] || :render_icon_placeholder)
        end
      end
    end

    def render_icon_placeholder
      tag.svg(class: size_config[:icon], fill: "currentColor", viewBox: "0 0 24 24", "aria-hidden": "true") do
        tag.path(d: "M24 20.993V24H0v-2.996A14.977 14.977 0 0112.004 15c4.904 0 9.26 2.354 11.996 5.993zM16.002 8.999a4 4 0 11-8 0 4 4 0 018 0z")
      end
    end

    def render_initials_placeholder
      tag.span(user_initials, class: class_names("font-semibold", size_config[:text]))
    end

    def user_initials
      return @user.initials if @user.respond_to?(:initials) && @user.initials.present?

      first = @user.first_name&.first || ""
      last = @user.last_name&.first || ""
      initials = "#{first}#{last}".upcase
      initials.presence || "?"
    end
  end
end
