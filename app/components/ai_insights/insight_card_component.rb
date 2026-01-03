# frozen_string_literal: true

module AiInsights
  # ViewComponent for displaying an AI productivity insight card.
  #
  # Displays a summary insight with title, value, description, and optional
  # trend indicator. Supports dismissible functionality via Turbo Streams.
  #
  # Usage:
  #   <%= render AiInsights::InsightCardComponent.new(
  #     type: :time_saved,
  #     title: "Time Saved by AI",
  #     value: "12.5 hours",
  #     description: "This week",
  #     trend: :up,
  #     detail_path: "/dashboard/insights/time_saved"
  #   ) %>
  #
  class InsightCardComponent < ApplicationComponent
    ICONS = {
      time_saved: "clock",
      code_contribution: "code-bracket",
      task_velocity: "rocket-launch",
      token_efficiency: "currency-dollar"
    }.freeze

    COLORS = {
      time_saved: "primary",
      code_contribution: "success",
      task_velocity: "secondary",
      token_efficiency: "accent"
    }.freeze

    TREND_ICONS = {
      up: "arrow-trending-up",
      down: "arrow-trending-down",
      neutral: "minus"
    }.freeze

    TREND_COLORS = {
      up: "text-success",
      down: "text-error",
      neutral: "text-base-content/50"
    }.freeze

    def initialize(
      type:,
      title:,
      value: nil,
      description: nil,
      trend: nil,
      trend_value: nil,
      detail_path: nil,
      dismissible: true,
      intro_key: nil,
      compact: false
    )
      @type = type.to_sym
      @title = title
      @value = value
      @description = description
      @trend = trend&.to_sym
      @trend_value = trend_value
      @detail_path = detail_path
      @dismissible = dismissible
      @intro_key = intro_key || "#{type}_intro"
      @compact = compact
    end

    def call
      render Ui::StatCardComponent.new(
        title: @title,
        value: @value,
        icon: icon_name,
        color:,
        description: @description,
        id: dom_id,
        data: stimulus_data
      ) do |c|
        c.with_footer do
          safe_join([
            render_dismiss_button,
            render_trend,
            render_action
          ].compact)
        end
      end
    end

    private

    def dom_id
      "insight-card-#{@type}"
    end

    def stimulus_data
      data = {
        controller: "insight-card",
        insight_card_type_value: @type.to_s,
        insight_card_intro_key_value: @intro_key
      }
      data[:action] = "click->insight-card#navigate" if @detail_path
      data[:insight_card_detail_path_value] = @detail_path if @detail_path
      data
    end

    def render_dismiss_button
      return unless @dismissible

      tag.button(
        class: "btn btn-ghost btn-xs btn-circle absolute top-2 right-2 opacity-50 hover:opacity-100",
        data: { action: "click->insight-card#dismiss" },
        title: "Dismiss",
        onclick: "event.stopPropagation();"
      ) do
        helpers.heroicon("x-mark", class: "w-4 h-4")
      end
    end

    def render_trend
      return unless @trend

      tag.div(class: "flex items-center gap-1 mt-2") do
        safe_join([
          helpers.heroicon(TREND_ICONS[@trend], class: "w-4 h-4 #{TREND_COLORS[@trend]}"),
          (@trend_value ? tag.span(@trend_value, class: "text-xs #{TREND_COLORS[@trend]}") : nil)
        ].compact)
      end
    end

    def render_action
      return unless @detail_path

      tag.div(class: "card-actions justify-end mt-auto pt-2") do
        tag.span(class: "text-xs text-#{color} hover:underline") do
          "View details"
        end
      end
    end

    def icon_name
      ICONS[@type] || "chart-bar"
    end

    def color
      COLORS[@type] || "primary"
    end

    def icon_container_classes
      "p-2 rounded-lg bg-#{color}/10 text-#{color}"
    end

    def content_padding_classes
      @compact ? "px-4 py-2" : "px-4 py-3"
    end

    def heroicon(name, **options)
      # Use inline SVG for Heroicons
      helpers.heroicon(name, **options)
    rescue NoMethodError
      # Fallback if heroicon helper is not available
      tag.svg(class: options[:class]) do
        tag.use(href: "#icon-#{name}")
      end
    end
  end
end
