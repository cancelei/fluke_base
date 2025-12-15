# frozen_string_literal: true

module Skeletons
  # List skeleton component for displaying loading state in lists
  #
  # @example Basic usage
  #   <%= render Skeletons::ListComponent.new(count: 5) %>
  #
  # @example Compact list without actions
  #   <%= render Skeletons::ListComponent.new(count: 3, variant: :compact, with_action: false) %>
  #
  class ListComponent < ApplicationComponent
    VARIANTS = {
      default: { avatar: "h-12 w-12", padding: "p-4", gap: "gap-4" },
      compact: { avatar: "h-8 w-8", padding: "p-2", gap: "gap-3" },
      large: { avatar: "h-16 w-16", padding: "p-5", gap: "gap-5" }
    }.freeze

    # @param count [Integer] Number of skeleton items
    # @param variant [Symbol] List item variant (:default, :compact, :large)
    # @param with_action [Boolean] Show action button skeleton
    # @param with_subtitle [Boolean] Show subtitle skeleton
    # @param divided [Boolean] Add dividers between items
    # @param css_class [String] Additional CSS classes
    # @param label [String] Accessible label
    def initialize(
      count: 5,
      variant: :default,
      with_action: true,
      with_subtitle: true,
      divided: true,
      css_class: nil,
      label: "Loading list"
    )
      @count = count
      @variant = VARIANTS[variant] || VARIANTS[:default]
      @with_action = with_action
      @with_subtitle = with_subtitle && variant != :compact
      @divided = divided
      @css_class = css_class
      @label = label
    end

    def call
      tag.ul(
        class: container_classes,
        role: "status",
        "aria-label": @label
      ) do
        safe_join([
          render_items,
          tag.span("#{@label}...", class: "sr-only")
        ])
      end
    end

    private

    def container_classes
      class_names(
        @divided ? "divide-y divide-base-200" : nil,
        @css_class
      )
    end

    def render_items
      safe_join(@count.times.map { render_item })
    end

    def render_item
      tag.li(class: "flex items-center #{@variant[:gap]} #{@variant[:padding]}") do
        safe_join([
          render_avatar,
          render_content,
          render_action
        ].compact)
      end
    end

    def render_avatar
      tag.div(class: "skeleton #{@variant[:avatar]} rounded-full shrink-0")
    end

    def render_content
      tag.div(class: "flex-1 flex flex-col gap-2") do
        safe_join([
          tag.div(class: "skeleton h-4 w-3/4"),
          @with_subtitle ? tag.div(class: "skeleton h-3 w-1/2") : nil
        ].compact)
      end
    end

    def render_action
      return nil unless @with_action

      tag.div(class: "skeleton h-8 w-16 rounded-lg shrink-0")
    end
  end
end
