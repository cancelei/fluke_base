# frozen_string_literal: true

module DashboardHelper
  # Render a detailed insight card for the insights overview page
  # @param type [Symbol] The insight type
  # @param title [String] The card title
  # @param icon [String] Heroicon name
  # @param color [String] DaisyUI color name
  # @param summary [Hash] The summary data
  # @return [String] Rendered HTML
  def render_insight_detail_card(type:, title:, icon:, color:, summary:)
    render Ui::CardComponent.new(variant: :minimal, css_class: "hover:shadow-lg transition-shadow") do |card|
      safe_join([
        # Header/Title section
        content_tag(:div, class: "flex items-center gap-3 mb-4") do
          safe_join([
            content_tag(:div, class: "p-3 rounded-lg bg-#{color}/10 text-#{color}") do
              heroicon(icon, class: "w-6 h-6")
            end,
            content_tag(:h3, title, class: "card-title text-lg")
          ])
        end,
        # Stats
        render_insight_stats(type, summary, color),
        # Action
        content_tag(:div, class: "card-actions justify-end mt-4") do
          link_to "View details", onboarding_insight_path(type), class: "btn btn-#{color} btn-sm btn-outline"
        end
      ])
    end
  end

  # Render statistics for an insight type
  def render_insight_stats(type, summary, color)
    case type
    when :time_saved
      render_time_saved_stats(summary, color)
    when :code_contribution
      render_code_stats(summary, color)
    when :task_velocity
      render_task_stats(summary, color)
    when :token_efficiency
      render_token_stats(summary, color)
    end
  end

  def render_time_saved_stats(summary, color)
    content_tag(:div, class: "stats stats-vertical lg:stats-horizontal shadow-none bg-base-200/50") do
      safe_join([
        stat_item("Time Saved", format_time_saved_value(summary), color),
        stat_item("Sessions", summary[:sessions].to_s, nil),
        stat_item("Efficiency", "#{summary[:efficiency_ratio]}x", nil)
      ])
    end
  end

  def render_code_stats(summary, color)
    content_tag(:div, class: "stats stats-vertical lg:stats-horizontal shadow-none bg-base-200/50") do
      safe_join([
        stat_item("Lines Added", "+#{summary[:lines_added]}", "success"),
        stat_item("Lines Removed", "-#{summary[:lines_removed]}", "error"),
        stat_item("Commits", summary[:commits].to_s, nil)
      ])
    end
  end

  def render_task_stats(summary, color)
    content_tag(:div, class: "stats stats-vertical lg:stats-horizontal shadow-none bg-base-200/50") do
      safe_join([
        stat_item("Completed", summary[:tasks_completed].to_s, color),
        stat_item("Created", summary[:tasks_created].to_s, nil),
        stat_item("Per Day", "#{summary[:velocity_per_day]}", nil)
      ])
    end
  end

  def render_token_stats(summary, color)
    content_tag(:div, class: "stats stats-vertical lg:stats-horizontal shadow-none bg-base-200/50") do
      safe_join([
        stat_item("Total Tokens", format_token_count(summary[:total_tokens]), color),
        stat_item("Est. Cost", "$#{summary[:estimated_cost_usd].round(2)}", nil),
        stat_item("Sessions", summary[:sessions].to_s, nil)
      ])
    end
  end

  def stat_item(title, value, color)
    content_tag(:div, class: "stat place-items-center py-2") do
      safe_join([
        content_tag(:div, title, class: "stat-title text-xs"),
        content_tag(:div, value, class: "stat-value text-lg #{color ? "text-#{color}" : ''}")
      ])
    end
  end

  def format_token_count(tokens)
    return "0" if tokens.nil? || tokens.zero?

    if tokens >= 1_000_000
      "#{(tokens / 1_000_000.0).round(1)}M"
    elsif tokens >= 1000
      "#{(tokens / 1000.0).round(1)}K"
    else
      tokens.to_s
    end
  end

  # Format the primary value for an insight card
  # @param insight [Hash] The insight hash from AiInsightsService
  # @return [String] Formatted value string
  def format_insight_value(insight)
    summary = insight[:summary]
    return nil unless summary

    case insight[:type]
    when :time_saved
      format_time_saved_value(summary)
    when :code_contribution
      format_code_contribution_value(summary)
    when :task_velocity
      format_task_velocity_value(summary)
    when :token_efficiency
      format_token_efficiency_value(summary)
    end
  end

  # Get the current user's onboarding progress
  # @return [UserOnboardingProgress, nil]
  def onboarding_progress
    @onboarding_progress ||= current_user&.onboarding_progress
  end

  # Get icon name for insight type
  def insight_icon(type)
    {
      time_saved: "clock",
      code_contribution: "code-bracket",
      task_velocity: "rocket-launch",
      token_efficiency: "currency-dollar"
    }[type.to_sym] || "chart-bar"
  end

  # Get color for insight type
  def insight_color(type)
    {
      time_saved: "primary",
      code_contribution: "success",
      task_velocity: "secondary",
      token_efficiency: "accent"
    }[type.to_sym] || "primary"
  end

  # Render detailed stats for individual insight page
  def render_detailed_insight_stats(type, summary)
    case type.to_sym
    when :time_saved
      render_detailed_time_saved_stats(summary)
    when :code_contribution
      render_detailed_code_stats(summary)
    when :task_velocity
      render_detailed_task_stats(summary)
    when :token_efficiency
      render_detailed_token_stats(summary)
    else
      ""
    end
  end

  def render_detailed_time_saved_stats(summary)
    content_tag(:div, class: "grid grid-cols-2 md:grid-cols-4 gap-6") do
      safe_join([
        large_stat("Total Saved", format_time_saved_value(summary), "primary", "Estimated time you would have spent manually"),
        large_stat("AI Time", "#{summary[:ai_time_minutes]&.round(1) || 0}m", nil, "Time AI spent processing"),
        large_stat("Efficiency", "#{summary[:efficiency_ratio] || 0}x", "success", "Time saved vs AI processing time"),
        large_stat("Sessions", summary[:sessions].to_s, nil, "Number of AI-assisted sessions")
      ])
    end
  end

  def render_detailed_code_stats(summary)
    content_tag(:div, class: "grid grid-cols-2 md:grid-cols-5 gap-6") do
      safe_join([
        large_stat("Lines Added", "+#{summary[:lines_added]}", "success", "New lines of code"),
        large_stat("Lines Removed", "-#{summary[:lines_removed]}", "error", "Deleted lines"),
        large_stat("Net Change", summary[:net_lines].to_s, nil, "Net lines added/removed"),
        large_stat("Files Changed", summary[:files_changed].to_s, nil, "Modified files"),
        large_stat("Commits", summary[:commits].to_s, nil, "Git commits")
      ])
    end
  end

  def render_detailed_task_stats(summary)
    content_tag(:div, class: "grid grid-cols-2 md:grid-cols-4 gap-6") do
      safe_join([
        large_stat("Completed", summary[:tasks_completed].to_s, "success", "Tasks finished"),
        large_stat("Created", summary[:tasks_created].to_s, nil, "Tasks created"),
        large_stat("Completion Rate", "#{(summary[:completion_rate] * 100).round}%", nil, "Tasks completed / created"),
        large_stat("Velocity", "#{summary[:velocity_per_day]}/day", "primary", "Average daily completion")
      ])
    end
  end

  def render_detailed_token_stats(summary)
    content_tag(:div, class: "grid grid-cols-2 md:grid-cols-5 gap-6") do
      safe_join([
        large_stat("Total Tokens", format_token_count(summary[:total_tokens]), "primary", "Combined input + output"),
        large_stat("Input", format_token_count(summary[:input_tokens]), nil, "Tokens sent to AI"),
        large_stat("Output", format_token_count(summary[:output_tokens]), nil, "Tokens received from AI"),
        large_stat("Est. Cost", "$#{summary[:estimated_cost_usd]&.round(2) || 0}", nil, "Estimated API cost"),
        large_stat("Cost/1K", "$#{summary[:cost_per_1k_tokens]&.round(4) || 0}", nil, "Cost per 1000 tokens")
      ])
    end
  end

  def large_stat(title, value, color, description = nil)
    content_tag(:div, class: "text-center") do
      safe_join([
        content_tag(:div, value, class: "text-3xl font-bold #{color ? "text-#{color}" : ''}"),
        content_tag(:div, title, class: "text-sm font-medium mt-1"),
        (description ? content_tag(:div, description, class: "text-xs text-base-content/50 mt-1") : nil)
      ].compact)
    end
  end

  # Render explanation text for how insight is calculated
  def render_insight_explanation(type)
    case type.to_sym
    when :time_saved
      content_tag(:div) do
        safe_join([
          content_tag(:p, "Time saved is estimated by categorizing AI tool usage and applying industry-standard time multipliers:"),
          content_tag(:ul, class: "mt-2 space-y-1") do
            safe_join([
              content_tag(:li, "Code generation: 5x multiplier (AI completes in minutes what might take an hour)"),
              content_tag(:li, "Documentation: 6x multiplier (AI can quickly generate docs, comments, README files)"),
              content_tag(:li, "Test generation: 5x multiplier (Creating test cases is time-intensive manually)"),
              content_tag(:li, "Refactoring: 4.5x multiplier (Structural changes across files)"),
              content_tag(:li, "Search operations: 4x multiplier (Finding relevant code/files)")
            ])
          end
        ])
      end
    when :code_contribution
      content_tag(:div) do
        safe_join([
          content_tag(:p, "Code contributions are tracked during AI-assisted sessions:"),
          content_tag(:ul, class: "mt-2 space-y-1") do
            safe_join([
              content_tag(:li, "Lines added/removed are detected by comparing file states before and after AI tool usage"),
              content_tag(:li, "Commits are attributed when made within an active AI session"),
              content_tag(:li, "Only changes in tracked project directories are counted")
            ])
          end
        ])
      end
    when :task_velocity
      content_tag(:div) do
        safe_join([
          content_tag(:p, "Task velocity is calculated from WeDo protocol task management:"),
          content_tag(:ul, class: "mt-2 space-y-1") do
            safe_join([
              content_tag(:li, "Tasks created and completed during AI sessions are tracked"),
              content_tag(:li, "Completion rate = tasks completed / tasks created"),
              content_tag(:li, "Daily velocity averages your completion rate over the selected period")
            ])
          end
        ])
      end
    when :token_efficiency
      content_tag(:div) do
        safe_join([
          content_tag(:p, "Token usage is tracked per AI session:"),
          content_tag(:ul, class: "mt-2 space-y-1") do
            safe_join([
              content_tag(:li, "Input tokens: text sent to the AI model"),
              content_tag(:li, "Output tokens: text received from the AI model"),
              content_tag(:li, "Costs are estimated using standard Claude API pricing"),
              content_tag(:li, "Sonnet: $3/$15 per million tokens (input/output)"),
              content_tag(:li, "Opus: $15/$75 per million tokens (input/output)")
            ])
          end
        ])
      end
    else
      ""
    end
  end

  private

  def format_time_saved_value(summary)
    hours = summary[:total_saved_hours].to_f
    if hours >= 1
      "#{hours.round(1)}h"
    else
      "#{summary[:total_saved_minutes].to_i}m"
    end
  end

  def format_code_contribution_value(summary)
    lines = summary[:lines_added].to_i
    if lines >= 1000
      "#{(lines / 1000.0).round(1)}K"
    else
      lines.to_s
    end
  end

  def format_task_velocity_value(summary)
    summary[:tasks_completed].to_s
  end

  def format_token_efficiency_value(summary)
    tokens = summary[:total_tokens].to_i
    if tokens >= 1_000_000
      "#{(tokens / 1_000_000.0).round(1)}M"
    elsif tokens >= 1000
      "#{(tokens / 1000.0).round(1)}K"
    else
      tokens.to_s
    end
  end
end
