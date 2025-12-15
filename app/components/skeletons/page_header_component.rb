# frozen_string_literal: true

module Skeletons
  # Page header skeleton component
  #
  # @example Basic usage
  #   <%= render Skeletons::PageHeaderComponent.new %>
  #
  # @example With title only (no action)
  #   <%= render Skeletons::PageHeaderComponent.new(with_action: false) %>
  #
  class PageHeaderComponent < ApplicationComponent
    # @param with_action [Boolean] Show action button skeleton
    # @param with_subtitle [Boolean] Show subtitle skeleton
    # @param css_class [String] Additional CSS classes
    # @param label [String] Accessible label
    def initialize(
      with_action: true,
      with_subtitle: true,
      css_class: nil,
      label: "Loading page header"
    )
      @with_action = with_action
      @with_subtitle = with_subtitle
      @css_class = css_class
      @label = label
    end

    def call
      tag.div(
        class: class_names("card bg-base-100 shadow-xl mb-8", @css_class),
        role: "status",
        "aria-label": @label
      ) do
        tag.div(class: "card-body") do
          safe_join([
            render_content,
            tag.span("#{@label}...", class: "sr-only")
          ])
        end
      end
    end

    private

    def render_content
      tag.div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4") do
        safe_join([
          render_title_section,
          render_action
        ].compact)
      end
    end

    def render_title_section
      tag.div do
        safe_join([
          tag.div(class: "skeleton h-8 w-48 mb-2"),
          @with_subtitle ? tag.div(class: "skeleton h-4 w-64") : nil
        ].compact)
      end
    end

    def render_action
      return nil unless @with_action

      tag.div(class: "flex-shrink-0") do
        tag.div(class: "skeleton h-10 w-32 rounded-lg")
      end
    end
  end
end
