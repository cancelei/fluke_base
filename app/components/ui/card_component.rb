# frozen_string_literal: true

module Ui
  class CardComponent < ApplicationComponent
    # DaisyUI card variant classes - simplified from glass-morphism
    VARIANTS = {
      default: "card bg-base-100 shadow-xl",
      simple: "card bg-base-100 shadow-lg",
      minimal: "card bg-base-100 shadow-md",
      gradient: "card bg-base-100 shadow-xl",
      elevated: "card bg-base-100 shadow-2xl",
      interactive: "card bg-base-100 shadow-lg hover:shadow-xl cursor-pointer transition-shadow",
      flat: "card bg-base-100 border border-base-300",
      compact: "card card-compact bg-base-100 shadow-md",
      bordered: "card bg-base-100 border border-base-300"
    }.freeze

    renders_one :header, "HeaderComponent"
    renders_one :footer, "FooterComponent"
    renders_many :sections, "SectionComponent"

    def initialize(variant: :default, padding: true, css_class: nil, **options)
      @variant = variant.to_sym
      @padding = padding
      @css_class = css_class
      @options = options
    end

    def call
      tag.div(class: combined_classes, **@options) do
        safe_join([
          header,
          body_content,
          sections,
          footer
        ].compact)
      end
    end

    private

    def body_content
      return unless content?

      tag.div(class: body_classes) { content }
    end

    def body_classes
      @padding ? "card-body" : ""
    end

    def combined_classes
      class_names(VARIANTS[@variant], @css_class)
    end

    # Nested component for header slot
    class HeaderComponent < ApplicationComponent
      def initialize(title: nil, subtitle: nil, css_class: nil)
        @title = title
        @subtitle = subtitle
        @css_class = css_class
      end

      def call
        tag.div(class: header_classes) do
          safe_join([
            render_title,
            render_subtitle,
            (content if content?)
          ].compact)
        end
      end

      private

      def header_classes
        class_names(
          "px-6 py-4 border-b border-base-200 bg-base-200/30",
          @css_class
        )
      end

      def render_title
        return unless @title

        tag.h3(@title, class: "card-title text-lg font-semibold")
      end

      def render_subtitle
        return unless @subtitle

        tag.p(@subtitle, class: "mt-1 text-sm opacity-70")
      end
    end

    # Nested component for footer slot
    class FooterComponent < ApplicationComponent
      def initialize(css_class: nil)
        @css_class = css_class
      end

      def call
        tag.div(class: footer_classes) { content }
      end

      private

      def footer_classes
        class_names(
          "card-actions px-6 py-4 bg-base-200/30 border-t border-base-200",
          @css_class
        )
      end
    end

    # Nested component for section slots
    class SectionComponent < ApplicationComponent
      def initialize(title: nil, css_class: nil)
        @title = title
        @css_class = css_class
      end

      def call
        tag.div(class: section_classes) do
          safe_join([
            (@title ? tag.h4(@title, class: "text-sm font-medium text-gray-900 mb-3") : nil),
            content
          ].compact)
        end
      end

      private

      def section_classes
        class_names("px-6 py-4 border-t border-base-200", @css_class)
      end
    end
  end
end
