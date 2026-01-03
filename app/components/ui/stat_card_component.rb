# frozen_string_literal: true

module Ui
  class StatCardComponent < ApplicationComponent
    renders_one :footer

    def initialize(title:, value:, icon: nil, color: "primary", subtitle: nil, description: nil, trend: nil, css_class: nil, **options)
      @title = title
      @value = value
      @icon = icon
      @color = color
      @subtitle = subtitle
      @description = description
      @trend = trend
      @css_class = css_class
      @options = options
    end

    def call
      render Ui::CardComponent.new(variant: :minimal, css_class: class_names("h-full hover:shadow-lg transition-shadow", @css_class), **@options) do
        tag.div(class: "flex flex-col h-full") do
          safe_join([
            render_header,
            render_content,
            (content if content?),
            (footer if footer?),
            render_default_footer
          ].compact)
        end
      end
    end

    private

    def render_header
      tag.div(class: "flex items-center justify-between mb-4") do
        safe_join([
          tag.div(class: "stat-title text-sm font-medium opacity-70") { @title },
          (@icon ? render_icon : nil)
        ].compact)
      end
    end

    def render_icon
      tag.div(class: "p-2 rounded-lg bg-#{@color}/10 text-#{@color}") do
        helpers.heroicon(@icon, class: "w-5 h-5")
      end
    end

    def render_content
      tag.div(class: "flex-1") do
        safe_join([
          tag.div(class: "stat-value text-3xl font-bold text-#{@color}") { @value.to_s.html_safe },
          (@subtitle ? tag.div(class: "stat-desc text-xs mt-1 opacity-60") { @subtitle } : nil)
        ].compact)
      end
    end

    def render_default_footer
      return unless (@description || @trend) && !footer?

      tag.div(class: "mt-4 pt-3 border-t border-base-200 text-xs opacity-60") do
        safe_join([
          (@trend ? render_trend : nil),
          (@description ? tag.span(@description) : nil)
        ].compact)
      end
    end

    def render_trend
      nil
    end
  end
end
