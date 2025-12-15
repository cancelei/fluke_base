# frozen_string_literal: true

module Skeletons
  # Stats skeleton component for displaying loading state in statistics displays
  #
  # @example Basic usage (3 stats horizontal)
  #   <%= render Skeletons::StatsComponent.new %>
  #
  # @example Vertical stats
  #   <%= render Skeletons::StatsComponent.new(count: 4, horizontal: false) %>
  #
  class StatsComponent < ApplicationComponent
    # @param count [Integer] Number of stat items
    # @param horizontal [Boolean] Display stats horizontally
    # @param with_icon [Boolean] Show icon placeholder in each stat
    # @param css_class [String] Additional CSS classes
    # @param label [String] Accessible label
    def initialize(
      count: 3,
      horizontal: true,
      with_icon: false,
      css_class: nil,
      label: "Loading statistics"
    )
      @count = count
      @horizontal = horizontal
      @with_icon = with_icon
      @css_class = css_class
      @label = label
    end

    def call
      tag.div(
        class: stats_classes,
        role: "status",
        "aria-label": @label
      ) do
        safe_join([
          render_stats,
          tag.span("#{@label}...", class: "sr-only")
        ])
      end
    end

    private

    def stats_classes
      class_names(
        "stats shadow bg-base-100 w-full",
        @horizontal ? "stats-horizontal" : "stats-vertical",
        @css_class
      )
    end

    def render_stats
      safe_join(@count.times.map { render_stat })
    end

    def render_stat
      tag.div(class: "stat") do
        safe_join([
          render_icon,
          tag.div(class: "stat-title") { tag.div(class: "skeleton h-3 w-16") },
          tag.div(class: "stat-value") { tag.div(class: "skeleton h-8 w-20 mt-2") },
          tag.div(class: "stat-desc") { tag.div(class: "skeleton h-3 w-24 mt-2") }
        ].compact)
      end
    end

    def render_icon
      return nil unless @with_icon

      tag.div(class: "stat-figure text-primary") do
        tag.div(class: "skeleton h-8 w-8 rounded")
      end
    end
  end
end
