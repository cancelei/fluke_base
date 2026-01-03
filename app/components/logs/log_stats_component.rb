# frozen_string_literal: true

module Logs
  # Displays live statistics for the log stream.
  # Shows entries/sec, buffer size, connection status, and type breakdown.
  class LogStatsComponent < ApplicationComponent
    def initialize(stats: {})
      @stats = stats.with_indifferent_access
    end

    def call
      tag.div(
        class: "grid grid-cols-2 md:grid-cols-4 gap-4",
        data: { unified_logs_target: "statsContainer" }
      ) do
        safe_join([
          render_stat_card(
            label: "Entries/sec",
            value: @stats[:entries_per_sec] || 0,
            icon: "bolt",
            color: "primary",
            target: "entriesPerSecStat"
          ),
          render_stat_card(
            label: "Buffer",
            value: "#{@stats[:buffer_count] || 0}/#{@stats[:buffer_capacity] || 10_000}",
            icon: "server-stack",
            color: "secondary",
            target: "bufferStat"
          ),
          render_stat_card(
            label: "Connected",
            value: @stats[:connected] ? "Yes" : "No",
            icon: "signal",
            color: @stats[:connected] ? "success" : "warning",
            target: "connectionStat"
          ),
          render_stat_card(
            label: "Clients",
            value: @stats[:connected_clients] || 0,
            icon: "users",
            color: "info",
            target: "clientsStat"
          )
        ])
      end
    end

    private

    def render_stat_card(label:, value:, icon:, color:, target:)
      tag.div(
        class: "stat bg-base-100 rounded-lg shadow-sm border border-base-300 p-3",
        data: { unified_logs_target: target }
      ) do
        safe_join([
          tag.div(class: "stat-figure text-#{color}") do
            render Ui::IconComponent.new(name: icon, size: :md)
          end,
          tag.div(class: "stat-title text-xs") { label },
          tag.div(class: "stat-value text-lg text-#{color}", data: { value_target: "display" }) { value.to_s }
        ])
      end
    end
  end
end
