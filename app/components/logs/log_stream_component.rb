# frozen_string_literal: true

module Logs
  # Container for real-time log stream with auto-scroll and pause functionality.
  # Works with unified_logs Stimulus controller for WebSocket updates.
  class LogStreamComponent < ApplicationComponent
    MAX_VISIBLE_ENTRIES = 500

    def initialize(
      entries: [],
      auto_scroll: true,
      paused: false,
      max_entries: MAX_VISIBLE_ENTRIES
    )
      @entries = entries
      @auto_scroll = auto_scroll
      @paused = paused
      @max_entries = max_entries
    end

    def call
      tag.div(
        class: "flex flex-col h-full bg-base-100 rounded-lg border border-base-300 overflow-hidden",
        data: {
          controller: "unified-logs",
          unified_logs_auto_scroll_value: @auto_scroll,
          unified_logs_paused_value: @paused,
          unified_logs_max_entries_value: @max_entries
        }
      ) do
        safe_join([
          render_toolbar,
          render_log_container,
          render_status_bar
        ])
      end
    end

    private

    def render_toolbar
      tag.div(class: "flex items-center justify-between px-4 py-2 bg-base-200/50 border-b border-base-300") do
        safe_join([
          render_stream_controls,
          render_entry_count,
          render_connection_status
        ])
      end
    end

    def render_stream_controls
      tag.div(class: "flex items-center gap-2") do
        safe_join([
          # Play/Pause button
          tag.button(
            type: "button",
            class: "btn btn-sm btn-ghost",
            data: {
              unified_logs_target: "pauseButton",
              action: "click->unified-logs#togglePause"
            }
          ) do
            safe_join([
              tag.span(data: { unified_logs_target: "pauseIcon" }) do
                render Ui::IconComponent.new(name: @paused ? "play" : "pause", size: :sm)
              end,
              tag.span(@paused ? "Resume" : "Pause", class: "ml-1 hidden sm:inline")
            ])
          end,

          # Clear button
          tag.button(
            type: "button",
            class: "btn btn-sm btn-ghost",
            data: { action: "click->unified-logs#clearLogs" }
          ) do
            safe_join([
              render(Ui::IconComponent.new(name: "trash", size: :sm)),
              tag.span("Clear", class: "ml-1 hidden sm:inline")
            ])
          end,

          # Auto-scroll toggle
          tag.label(class: "flex items-center gap-1 cursor-pointer") do
            safe_join([
              tag.input(
                type: "checkbox",
                class: "checkbox checkbox-sm checkbox-primary",
                checked: @auto_scroll,
                data: {
                  unified_logs_target: "autoScrollCheckbox",
                  action: "change->unified-logs#toggleAutoScroll"
                }
              ),
              tag.span("Auto-scroll", class: "text-sm")
            ])
          end
        ])
      end
    end

    def render_entry_count
      tag.div(class: "flex items-center gap-2 text-sm text-base-content/70") do
        safe_join([
          tag.span(data: { unified_logs_target: "entryCount" }) { @entries.size.to_s },
          tag.span("entries"),
          tag.span("|", class: "opacity-50"),
          tag.span(data: { unified_logs_target: "entriesPerSec" }) { "0" },
          tag.span("/sec")
        ])
      end
    end

    def render_connection_status
      tag.div(
        class: "flex items-center gap-2",
        data: { unified_logs_target: "connectionStatus" }
      ) do
        safe_join([
          tag.span(class: "w-2 h-2 rounded-full bg-warning animate-pulse", data: { unified_logs_target: "statusDot" }),
          tag.span("Connecting...", class: "text-sm", data: { unified_logs_target: "statusText" })
        ])
      end
    end

    def render_log_container
      tag.div(
        class: "flex-grow overflow-y-auto font-mono text-sm",
        data: { unified_logs_target: "logContainer" }
      ) do
        tag.div(
          class: "divide-y divide-base-200",
          data: { unified_logs_target: "logList" }
        ) do
          if @entries.any?
            safe_join(@entries.map { |entry| render_entry(entry) })
          else
            render_empty_state
          end
        end
      end
    end

    def render_entry(entry)
      render Logs::LogEntryComponent.new(entry:)
    end

    def render_empty_state
      tag.div(class: "flex flex-col items-center justify-center py-16 text-base-content/50") do
        safe_join([
          render(Ui::IconComponent.new(name: "document-text", size: :xl, css_class: "opacity-30 mb-4")),
          tag.p("No log entries yet", class: "text-lg font-medium"),
          tag.p("Logs will appear here in real-time once connected", class: "text-sm mt-1")
        ])
      end
    end

    def render_status_bar
      tag.div(
        class: "px-4 py-2 bg-base-200/30 border-t border-base-300 text-xs text-base-content/60",
        data: { unified_logs_target: "statusBar" }
      ) do
        safe_join([
          tag.span("Buffer: "),
          tag.span("0", data: { unified_logs_target: "bufferSize" }),
          tag.span("/#{@max_entries}"),
          tag.span(" | ", class: "mx-2"),
          tag.span("Last update: "),
          tag.span("--:--:--", data: { unified_logs_target: "lastUpdate" })
        ])
      end
    end
  end
end
