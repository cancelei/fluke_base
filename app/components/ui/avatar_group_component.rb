# frozen_string_literal: true

module Ui
  class AvatarGroupComponent < ApplicationComponent
    # Size configurations with overlap spacing matching avatar sizes
    SIZES = {
      xs: { overlap: "-space-x-2", avatar_size: :xs, badge_container: "w-6 h-6", badge_text: "text-xs" },
      sm: { overlap: "-space-x-3", avatar_size: :sm, badge_container: "w-8 h-8", badge_text: "text-xs" },
      md: { overlap: "-space-x-4", avatar_size: :md, badge_container: "w-12 h-12", badge_text: "text-sm" },
      lg: { overlap: "-space-x-5", avatar_size: :lg, badge_container: "w-16 h-16", badge_text: "text-base" }
    }.freeze

    DEFAULT_MAX_VISIBLE = 3
    MAX_OVERFLOW_DISPLAY = 10

    # @param users [Array<User>] Collection of users to display
    # @param size [Symbol] Avatar size (:xs, :sm, :md, :lg)
    # @param max_visible [Integer] Maximum avatars before overflow badge (default: 3)
    # @param show_popover [Boolean] Enable hover popovers (default: true)
    # @param role_method [Symbol, nil] Method to call on user for role display
    # @param role_context [Object, nil] Context to pass to role_method
    # @param link_to_profile [Boolean] Make avatars clickable to profile (default: true)
    # @param ring [Boolean] Show ring around avatars (default: true)
    # @param ring_color [String] Ring color (default: "base-100")
    # @param css_class [String, nil] Additional CSS classes
    def initialize(
      users:,
      size: :sm,
      max_visible: DEFAULT_MAX_VISIBLE,
      show_popover: true,
      role_method: nil,
      role_context: nil,
      link_to_profile: true,
      ring: true,
      ring_color: "base-100",
      css_class: nil
    )
      @users = Array(users).compact
      @size = size.to_sym
      @max_visible = max_visible
      @show_popover = show_popover
      @role_method = role_method
      @role_context = role_context
      @link_to_profile = link_to_profile
      @ring = ring
      @ring_color = ring_color
      @css_class = css_class
    end

    def render?
      @users.any?
    end

    def visible_users
      @users.take(@max_visible)
    end

    def overflow_users
      @users.drop(@max_visible).take(MAX_OVERFLOW_DISPLAY)
    end

    def overflow_count
      [@users.size - @max_visible, 0].max
    end

    def has_overflow?
      overflow_count > 0
    end

    def total_overflow_count
      @users.size - @max_visible
    end

    def size_config
      SIZES[@size] || SIZES[:sm]
    end

    def container_classes
      class_names(
        "avatar-group rtl:space-x-reverse",
        size_config[:overlap],
        @css_class
      )
    end

    def user_role(user)
      return nil unless @role_method && user.respond_to?(@role_method)

      if @role_context
        user.send(@role_method, @role_context)
      else
        user.send(@role_method)
      end
    end

    def profile_path(user)
      helpers.person_path(user)
    end

    def overflow_badge_classes
      class_names(
        "bg-neutral text-neutral-content rounded-full flex items-center justify-center",
        size_config[:badge_container],
        @ring ? "ring ring-#{@ring_color} ring-offset-base-100 ring-offset-2" : nil
      )
    end

    def overflow_text_classes
      class_names("font-medium", size_config[:badge_text])
    end

    def avatar_ring_color
      @ring_color
    end

    def avatar_size
      size_config[:avatar_size]
    end

    def show_popover?
      @show_popover
    end

    def link_to_profile?
      @link_to_profile
    end

    def show_ring?
      @ring
    end
  end
end
