# frozen_string_literal: true

module Ui
  class PageHeaderComponent < ApplicationComponent
    renders_one :actions, "ActionsComponent"

    def initialize(
      title:,
      subtitle: nil,
      container_class: nil,
      inner_class: nil,
      title_class: nil,
      subtitle_class: nil,
      title_section_class: nil
    )
      @title = title
      @subtitle = subtitle
      @container_class = container_class
      @inner_class = inner_class
      @title_class = title_class
      @subtitle_class = subtitle_class
      @title_section_class = title_section_class
    end

    def call
      tag.div(class: container_classes) do
        tag.div(class: inner_classes) do
          tag.div(class: "flex items-center justify-between mb-6") do
            safe_join([ render_title_section, render_actions ].compact)
          end
        end
      end
    end

    private

    def container_classes
      @container_class || "max-w-7xl mx-auto py-6 sm:px-6 lg:px-8"
    end

    def inner_classes
      @inner_class || "px-4 py-6 sm:px-0"
    end

    def render_title_section
      tag.div(class: title_section_classes) do
        safe_join([ render_title, render_subtitle ].compact)
      end
    end

    def title_section_classes
      @title_section_class || "flex-1 min-w-0"
    end

    def render_title
      tag.h1(@title, class: title_classes)
    end

    def title_classes
      @title_class || "text-2xl font-semibold text-gray-900"
    end

    def render_subtitle
      return nil unless @subtitle

      tag.p(@subtitle, class: subtitle_classes)
    end

    def subtitle_classes
      @subtitle_class || "mt-2 text-sm text-gray-700"
    end

    def render_actions
      return nil unless actions?

      actions
    end

    # Nested component for actions slot
    class ActionsComponent < ApplicationComponent
      def initialize(css_class: nil)
        @css_class = css_class
      end

      def call
        tag.div(class: combined_classes) { content }
      end

      private

      def combined_classes
        class_names("mt-4 sm:mt-0", @css_class)
      end
    end
  end
end
