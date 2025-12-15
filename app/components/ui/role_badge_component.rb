# frozen_string_literal: true

module Ui
  class RoleBadgeComponent < ApplicationComponent
    # Role-specific DaisyUI styles with icons
    ROLE_STYLES = {
      owner: {
        variant: "badge-primary",
        label: "Owner",
        icon: "crown"
      },
      admin: {
        variant: "badge-secondary",
        label: "Admin",
        icon: "shield-check"
      },
      member: {
        variant: "badge-accent",
        label: "Member",
        icon: "user"
      },
      guest: {
        variant: "badge-ghost",
        label: "Guest",
        icon: "eye"
      }
    }.freeze

    SIZES = {
      xs: "badge-xs",
      sm: "badge-sm",
      md: "",
      lg: "badge-lg"
    }.freeze

    ICON_SIZES = {
      xs: "h-2.5 w-2.5",
      sm: "h-3 w-3",
      md: "h-3.5 w-3.5",
      lg: "h-4 w-4"
    }.freeze

    def initialize(role:, size: :md, show_icon: true, css_class: nil)
      @role = role.to_s.downcase.to_sym
      @size = size.to_sym
      @show_icon = show_icon
      @css_class = css_class
      @style = ROLE_STYLES[@role] || ROLE_STYLES[:guest]
    end

    def call
      tag.span(class: badge_classes) do
        safe_join([
          (@show_icon ? render_icon : nil),
          tag.span(@style[:label])
        ].compact)
      end
    end

    private

    def badge_classes
      class_names(
        "badge gap-1",
        @style[:variant],
        SIZES[@size],
        @css_class
      )
    end

    def render_icon
      case @style[:icon]
      when "crown"
        crown_icon
      when "shield-check"
        shield_check_icon
      when "user"
        user_icon
      when "eye"
        eye_icon
      end
    end

    def crown_icon
      tag.svg(class: icon_classes, fill: "currentColor", viewBox: "0 0 20 20") do
        tag.path(
          fill_rule: "evenodd",
          d: "M10 2a1 1 0 011 1v1.323l3.954 1.582 1.599-.8a1 1 0 01.894 1.79l-1.233.617 1.738 5.42a1 1 0 01-.285 1.05A3.989 3.989 0 0115 15a3.989 3.989 0 01-2.667-1.018 1 1 0 01-.285-1.05l1.715-5.349L11 6.477V16h2a1 1 0 110 2H7a1 1 0 110-2h2V6.477L6.237 7.583l1.715 5.349a1 1 0 01-.285 1.05A3.989 3.989 0 015 15a3.989 3.989 0 01-2.667-1.018 1 1 0 01-.285-1.05l1.738-5.42-1.233-.617a1 1 0 01.894-1.79l1.599.8L9 4.323V3a1 1 0 011-1z",
          clip_rule: "evenodd"
        )
      end
    end

    def shield_check_icon
      tag.svg(class: icon_classes, fill: "currentColor", viewBox: "0 0 20 20") do
        tag.path(
          fill_rule: "evenodd",
          d: "M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z",
          clip_rule: "evenodd"
        )
      end
    end

    def user_icon
      tag.svg(class: icon_classes, fill: "currentColor", viewBox: "0 0 20 20") do
        tag.path(
          fill_rule: "evenodd",
          d: "M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z",
          clip_rule: "evenodd"
        )
      end
    end

    def eye_icon
      tag.svg(class: icon_classes, fill: "currentColor", viewBox: "0 0 20 20") do
        tag.path(d: "M10 12a2 2 0 100-4 2 2 0 000 4z") +
          tag.path(
            fill_rule: "evenodd",
            d: "M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z",
            clip_rule: "evenodd"
          )
      end
    end

    def icon_classes
      ICON_SIZES[@size]
    end
  end
end
