# frozen_string_literal: true

module Skeletons
  # Grid skeleton component for displaying multiple skeleton cards in a responsive grid
  #
  # @example Basic usage
  #   <%= render Skeletons::GridComponent.new(variant: :project_card, count: 6) %>
  #
  # @example With custom columns
  #   <%= render Skeletons::GridComponent.new(
  #     variant: :user_card,
  #     count: 4,
  #     columns: { sm: 2, lg: 3, xl: 4 }
  #   ) %>
  #
  class GridComponent < ApplicationComponent
    COLUMN_PRESETS = {
      projects: { sm: 2, lg: 3, "2xl": 4 },
      users: { sm: 2, lg: 3, xl: 4 },
      agreements: { sm: 1, md: 2, lg: 3 },
      compact: { sm: 2, md: 3, lg: 4, xl: 5 },
      single: { sm: 1 },
      default: { sm: 2, lg: 3 }
    }.freeze

    GAP_CLASSES = {
      xs: "gap-2",
      sm: "gap-4",
      md: "gap-6",
      lg: "gap-8",
      xl: "gap-10"
    }.freeze

    # @param variant [Symbol] The skeleton variant for each item (:project_card, :user_card, etc.)
    # @param count [Integer] Number of skeleton items
    # @param columns [Hash, Symbol] Column configuration or preset name
    # @param gap [Symbol] Gap between items (:xs, :sm, :md, :lg, :xl)
    # @param css_class [String] Additional CSS classes
    # @param stagger [Boolean] Apply staggered animation
    # @param label [String] Accessible label for screen readers
    def initialize(
      variant: :card,
      count: 6,
      columns: :default,
      gap: :md,
      css_class: nil,
      stagger: true,
      label: "Loading content"
    )
      @variant = variant
      @count = count
      @columns = columns.is_a?(Symbol) ? COLUMN_PRESETS[columns] : columns
      @gap = gap
      @css_class = css_class
      @stagger = stagger
      @label = label
    end

    def call
      tag.div(
        class: grid_classes,
        role: "status",
        "aria-label": @label
      ) do
        safe_join([
          render_skeletons,
          tag.span("#{@label}...", class: "sr-only")
        ])
      end
    end

    private

    def grid_classes
      class_names(
        "grid grid-cols-1",
        column_classes,
        GAP_CLASSES[@gap],
        @css_class
      )
    end

    def column_classes
      classes = []
      classes << "sm:grid-cols-#{@columns[:sm]}" if @columns[:sm]
      classes << "md:grid-cols-#{@columns[:md]}" if @columns[:md]
      classes << "lg:grid-cols-#{@columns[:lg]}" if @columns[:lg]
      classes << "xl:grid-cols-#{@columns[:xl]}" if @columns[:xl]
      classes << "2xl:grid-cols-#{@columns[:'2xl']}" if @columns[:'2xl']
      classes.join(" ")
    end

    def render_skeletons
      safe_join(@count.times.map do |i|
        render Ui::SkeletonComponent.new(
          variant: @variant,
          stagger: @stagger
        )
      end)
    end
  end
end
