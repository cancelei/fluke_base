# frozen_string_literal: true

module Logs
  # Filter controls for the unified logs dashboard.
  # Includes type toggles, level selector, sandbox dropdown, and search input.
  class LogFilterComponent < ApplicationComponent
    LOG_TYPES = [
      { value: "mcp", label: "MCP", icon: "command-line", color: "primary" },
      { value: "container", label: "Container", icon: "cube", color: "secondary" },
      { value: "application", label: "App", icon: "document-text", color: "accent" }
    ].freeze

    LOG_LEVELS = [
      { value: "trace", label: "Trace" },
      { value: "debug", label: "Debug" },
      { value: "info", label: "Info" },
      { value: "warn", label: "Warn" },
      { value: "error", label: "Error" },
      { value: "fatal", label: "Fatal" }
    ].freeze

    def initialize(
      sandboxes: [],
      selected_types: nil,
      selected_levels: nil,
      selected_sandbox: nil,
      search_query: nil
    )
      @sandboxes = sandboxes
      @selected_types = selected_types || LOG_TYPES.map { |t| t[:value] }
      @selected_levels = selected_levels || %w[info warn error fatal]
      @selected_sandbox = selected_sandbox
      @search_query = search_query
    end

    def call
      tag.div(
        class: "flex flex-wrap items-center gap-4 p-4 bg-base-200/50 rounded-lg",
        data: {
          controller: "log-filter",
          log_filter_selected_types_value: @selected_types.to_json,
          log_filter_selected_levels_value: @selected_levels.to_json
        }
      ) do
        safe_join([
          render_type_toggles,
          render_level_select,
          render_sandbox_select,
          render_search_input,
          render_clear_button
        ])
      end
    end

    private

    def render_type_toggles
      tag.div(class: "flex items-center gap-1", data: { log_filter_target: "typeToggles" }) do
        safe_join([
          tag.span("Types:", class: "text-sm font-medium mr-2"),
          *LOG_TYPES.map { |type| render_type_toggle(type) }
        ])
      end
    end

    def render_type_toggle(type)
      active = @selected_types.include?(type[:value])

      tag.button(
        type: "button",
        class: class_names(
          "btn btn-sm gap-1",
          active ? "btn-#{type[:color]}" : "btn-ghost"
        ),
        data: {
          action: "click->log-filter#toggleType",
          type: type[:value]
        }
      ) do
        safe_join([
          render(Ui::IconComponent.new(name: type[:icon], size: :xs)),
          tag.span(type[:label])
        ])
      end
    end

    def render_level_select
      tag.div(class: "flex items-center gap-2") do
        safe_join([
          tag.span("Level:", class: "text-sm font-medium"),
          tag.select(
            class: "select select-bordered select-sm w-32",
            data: {
              log_filter_target: "levelSelect",
              action: "change->log-filter#updateLevels"
            }
          ) do
            safe_join([
              tag.option("All", value: "all"),
              tag.option("Info+", value: "info", selected: @selected_levels == %w[info warn error fatal]),
              tag.option("Warn+", value: "warn", selected: @selected_levels == %w[warn error fatal]),
              tag.option("Error+", value: "error", selected: @selected_levels == %w[error fatal]),
              tag.option("Custom...", value: "custom")
            ])
          end
        ])
      end
    end

    def render_sandbox_select
      return nil if @sandboxes.empty?

      tag.div(class: "flex items-center gap-2") do
        safe_join([
          tag.span("Sandbox:", class: "text-sm font-medium"),
          tag.select(
            class: "select select-bordered select-sm w-40",
            data: {
              log_filter_target: "sandboxSelect",
              action: "change->log-filter#updateSandbox"
            }
          ) do
            safe_join([
              tag.option("All Sandboxes", value: ""),
              *@sandboxes.map do |sandbox|
                tag.option(
                  sandbox[:name] || sandbox[:id],
                  value: sandbox[:id],
                  selected: @selected_sandbox == sandbox[:id]
                )
              end
            ])
          end
        ])
      end
    end

    def render_search_input
      tag.div(class: "flex-grow min-w-48") do
        tag.div(class: "join w-full") do
          safe_join([
            tag.input(
              type: "text",
              placeholder: "Search logs...",
              value: @search_query,
              class: "input input-bordered input-sm join-item flex-grow",
              data: {
                log_filter_target: "searchInput",
                action: "input->log-filter#debounceSearch keydown.enter->log-filter#applyFilter"
              }
            ),
            tag.button(
              type: "button",
              class: "btn btn-sm btn-primary join-item",
              data: { action: "click->log-filter#applyFilter" }
            ) do
              render Ui::IconComponent.new(name: "magnifying-glass", size: :xs)
            end
          ])
        end
      end
    end

    def render_clear_button
      tag.button(
        type: "button",
        class: "btn btn-sm btn-ghost",
        data: { action: "click->log-filter#clearFilters" }
      ) do
        safe_join([
          render(Ui::IconComponent.new(name: "x-mark", size: :xs)),
          tag.span("Clear", class: "hidden sm:inline")
        ])
      end
    end
  end
end
