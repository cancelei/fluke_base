# frozen_string_literal: true

module Logs
  # Renders a single log entry with type icon, level indicator, timestamp, and message.
  # Designed for real-time log streaming display.
  class LogEntryComponent < ApplicationComponent
    LOG_TYPE_CONFIG = {
      mcp: {
        icon: "command-line",
        label: "MCP",
        bg_class: "bg-primary/10",
        text_class: "text-primary",
        border_class: "border-l-primary"
      },
      container: {
        icon: "cube",
        label: "Container",
        bg_class: "bg-secondary/10",
        text_class: "text-secondary",
        border_class: "border-l-secondary"
      },
      application: {
        icon: "document-text",
        label: "App",
        bg_class: "bg-accent/10",
        text_class: "text-accent",
        border_class: "border-l-accent"
      },
      ai_provider: {
        icon: "sparkles",
        label: "AI",
        bg_class: "bg-info/10",
        text_class: "text-info",
        border_class: "border-l-info"
      }
    }.freeze

    LOG_LEVEL_CONFIG = {
      trace: { color: "base-content/50", icon: nil },
      debug: { color: "info", icon: "bug-ant" },
      info: { color: "success", icon: "information-circle" },
      warn: { color: "warning", icon: "exclamation-triangle" },
      error: { color: "error", icon: "x-circle" },
      fatal: { color: "error", icon: "fire" }
    }.freeze

    # SECURITY: Allowed values for cross-framework data validation
    ALLOWED_TYPES = %i[mcp container application ai_provider].freeze
    ALLOWED_LEVELS = %i[trace debug info warn error fatal].freeze

    def initialize(entry:, show_source: true, compact: false)
      # SECURITY: Sanitize entry from external Python source
      @entry = sanitize_entry(entry)
      @show_source = show_source
      @compact = compact
    end

    private

    def sanitize_entry(entry)
      return {} unless entry.is_a?(Hash)

      sanitized = entry.with_indifferent_access

      # Ensure message is a string and truncate excessively long messages
      if sanitized[:message]
        sanitized[:message] = sanitized[:message].to_s.truncate(10_000)
      end

      # Validate source type
      if sanitized[:source].is_a?(Hash)
        raw_type = sanitized[:source][:type].to_s.downcase.to_sym
        sanitized[:source][:type] = ALLOWED_TYPES.include?(raw_type) ? raw_type : :application
      end

      # Validate level
      raw_level = sanitized[:level].to_s.downcase.to_sym
      sanitized[:level] = ALLOWED_LEVELS.include?(raw_level) ? raw_level : :info

      sanitized
    end

    public

    def call
      tag.div(class: entry_classes, data: entry_data) do
        safe_join([
          render_type_indicator,
          render_timestamp,
          render_level_badge,
          render_message,
          (render_source if @show_source),
          render_expand_button
        ].compact)
      end
    end

    private

    def entry_classes
      type_config = LOG_TYPE_CONFIG[log_type] || LOG_TYPE_CONFIG[:application]

      class_names(
        "flex items-center gap-2 px-3 py-1.5 border-l-2 hover:bg-base-200/50 transition-colors",
        type_config[:border_class],
        @compact ? "text-xs" : "text-sm",
        level == :error || level == :fatal ? "bg-error/5" : nil
      )
    end

    def entry_data
      {
        log_id: @entry[:id],
        log_type: log_type,
        log_level: level,
        timestamp: @entry[:timestamp]
      }
    end

    def render_type_indicator
      config = LOG_TYPE_CONFIG[log_type] || LOG_TYPE_CONFIG[:application]

      tag.span(class: "flex-shrink-0 w-6 text-center #{config[:text_class]}", title: config[:label]) do
        render Ui::IconComponent.new(name: config[:icon], size: :xs)
      end
    end

    def render_timestamp
      time = parse_timestamp(@entry[:timestamp])
      formatted = time ? time.strftime("%H:%M:%S.%L") : @entry[:timestamp]

      tag.span(formatted, class: "flex-shrink-0 font-mono text-base-content/60 w-24")
    end

    def render_level_badge
      config = LOG_LEVEL_CONFIG[level] || LOG_LEVEL_CONFIG[:info]

      tag.span(
        level.to_s.upcase[0..2],
        class: "flex-shrink-0 w-8 text-center font-bold text-#{config[:color]}"
      )
    end

    def render_message
      tag.span(class: "flex-grow truncate font-mono") do
        @entry[:message]
      end
    end

    def render_source
      source = @entry[:source]
      return unless source

      # AI provider: show provider and model
      if log_type == :ai_provider
        provider = source[:provider]
        model = source[:model]
        source_text = [provider, model&.then { "(#{_1})" }].compact.join(" ")
      else
        source_text = source[:agent_id] || source[:container_name] || source[:sandbox_id]
      end
      return unless source_text.present?

      tag.span(source_text, class: "flex-shrink-0 text-base-content/50 text-xs max-w-32 truncate")
    end

    def render_expand_button
      # Only for entries with additional metadata
      return unless has_metadata?

      tag.button(
        class: "btn btn-ghost btn-xs flex-shrink-0",
        data: { action: "click->unified-logs#toggleEntryDetails" }
      ) do
        render Ui::IconComponent.new(name: "chevron-down", size: :xs)
      end
    end

    def log_type
      type = @entry.dig(:source, :type) || @entry[:type] || "application"
      type.to_s.downcase.to_sym
    end

    def level
      (@entry[:level] || "info").to_s.downcase.to_sym
    end

    def parse_timestamp(ts)
      return nil unless ts

      Time.parse(ts)
    rescue ArgumentError
      nil
    end

    def has_metadata?
      @entry[:mcp_metadata].present? ||
        @entry[:container_metadata].present? ||
        @entry[:app_metadata].present? ||
        @entry[:ai_metadata].present? ||
        @entry[:tags].present?
    end
  end
end
