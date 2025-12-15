# frozen_string_literal: true

module Skeletons
  # Dashboard widget skeleton component
  #
  # @example Basic usage
  #   <%= render Skeletons::DashboardWidgetComponent.new %>
  #
  # @example With title
  #   <%= render Skeletons::DashboardWidgetComponent.new(title: "Recent Projects", items: 4) %>
  #
  class DashboardWidgetComponent < ApplicationComponent
    # @param title [String, nil] Optional widget title (shows skeleton if nil)
    # @param items [Integer] Number of skeleton items to show
    # @param with_header_action [Boolean] Show header action button skeleton
    # @param css_class [String] Additional CSS classes
    # @param label [String] Accessible label
    def initialize(
      title: nil,
      items: 3,
      with_header_action: true,
      css_class: nil,
      label: "Loading widget"
    )
      @title = title
      @items = items
      @with_header_action = with_header_action
      @css_class = css_class
      @label = label
    end

    def call
      tag.div(
        class: class_names("card bg-base-100 shadow-xl", @css_class),
        role: "status",
        "aria-label": @label
      ) do
        tag.div(class: "card-body") do
          safe_join([
            render_header,
            render_items,
            tag.span("#{@label}...", class: "sr-only")
          ])
        end
      end
    end

    private

    def render_header
      tag.div(class: "flex justify-between items-center mb-4") do
        safe_join([
          render_title,
          @with_header_action ? tag.div(class: "skeleton h-6 w-16 rounded-lg") : nil
        ].compact)
      end
    end

    def render_title
      if @title.present?
        tag.h3(@title, class: "card-title text-lg")
      else
        tag.div(class: "skeleton h-6 w-40")
      end
    end

    def render_items
      tag.div(class: "space-y-3") do
        safe_join(@items.times.map { render_item })
      end
    end

    def render_item
      tag.div(class: "flex items-center gap-3 py-2") do
        safe_join([
          tag.div(class: "skeleton h-10 w-10 rounded-lg shrink-0"),
          tag.div(class: "flex-1") do
            safe_join([
              tag.div(class: "skeleton h-4 w-3/4 mb-1"),
              tag.div(class: "skeleton h-3 w-1/2")
            ])
          end
        ])
      end
    end
  end
end
