# frozen_string_literal: true

module Skeletons
  # Full page skeleton component for displaying loading state for entire pages
  #
  # @example Basic dashboard page
  #   <%= render Skeletons::PageComponent.new(layout: :dashboard) %>
  #
  # @example List page with header
  #   <%= render Skeletons::PageComponent.new(layout: :list, items: 10) %>
  #
  # @example Custom layout
  #   <%= render Skeletons::PageComponent.new do |page| %>
  #     <% page.with_header %>
  #     <% page.with_body do %>
  #       <%= render Skeletons::GridComponent.new(variant: :project_card, count: 6) %>
  #     <% end %>
  #   <% end %>
  #
  class PageComponent < ApplicationComponent
    renders_one :header, ->(**args) { Skeletons::PageHeaderComponent.new(**args) }
    renders_one :body

    LAYOUTS = {
      dashboard: { header: true, widgets: 3, list: 0 },
      list: { header: true, widgets: 0, list: 5 },
      grid: { header: true, widgets: 0, grid: 6 },
      detail: { header: true, widgets: 0, detail: true },
      form: { header: true, widgets: 0, form: 5 }
    }.freeze

    # @param layout [Symbol, nil] Predefined layout (:dashboard, :list, :grid, :detail, :form)
    # @param items [Integer] Number of items for lists/grids
    # @param css_class [String] Additional CSS classes
    def initialize(layout: nil, items: 5, css_class: nil)
      @layout = layout
      @items = items
      @css_class = css_class
      @config = LAYOUTS[layout] || {}
    end

    def call
      tag.div(class: class_names("space-y-6", @css_class)) do
        if body? || header?
          render_custom_content
        else
          render_layout
        end
      end
    end

    private

    def render_custom_content
      safe_join([
        header,
        body
      ].compact)
    end

    def render_layout
      parts = []

      # Header
      parts << render(Skeletons::PageHeaderComponent.new) if @config[:header]

      # Dashboard widgets
      if @config[:widgets]&.positive?
        parts << tag.div(class: "grid grid-cols-1 gap-6 lg:grid-cols-3") do
          safe_join(@config[:widgets].times.map { render(Skeletons::DashboardWidgetComponent.new) })
        end
      end

      # List content
      if @config[:list]&.positive?
        parts << tag.div(class: "card bg-base-100 shadow-xl") do
          tag.div(class: "card-body") do
            render(Skeletons::ListComponent.new(count: @items))
          end
        end
      end

      # Grid content
      if @config[:grid]&.positive?
        parts << render(Skeletons::GridComponent.new(variant: :project_card, count: @items))
      end

      # Detail page content
      if @config[:detail]
        parts << render_detail_skeleton
      end

      # Form content
      if @config[:form]&.positive?
        parts << tag.div(class: "card bg-base-100 shadow-xl") do
          tag.div(class: "card-body") do
            render(Skeletons::FormComponent.new(fields: @items))
          end
        end
      end

      safe_join(parts)
    end

    def render_detail_skeleton
      tag.div(class: "grid grid-cols-1 lg:grid-cols-3 gap-6") do
        safe_join([
          # Main content (2/3)
          tag.div(class: "lg:col-span-2 space-y-6") do
            safe_join([
              render(Ui::SkeletonComponent.new(variant: :card)),
              render(Ui::SkeletonComponent.new(variant: :card))
            ])
          end,
          # Sidebar (1/3)
          tag.div(class: "space-y-6") do
            safe_join([
              render(Skeletons::DashboardWidgetComponent.new(items: 2)),
              render(Skeletons::StatsComponent.new(count: 2, horizontal: false))
            ])
          end
        ])
      end
    end
  end
end
