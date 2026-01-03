# frozen_string_literal: true

# Service for generating and managing AI productivity insights.
#
# Provides dashboard insights based on user's onboarding stage,
# aggregates metrics, and tracks which insights have been viewed.
#
# Usage:
#   service = AiInsightsService.new(user: current_user, project: project)
#   insights = service.dashboard_insights
#   service.mark_insight_seen(:time_saved_intro)
#
class AiInsightsService
  INSIGHT_TYPES = %i[
    time_saved
    code_contribution
    task_velocity
    token_efficiency
  ].freeze

  # Priority order for displaying insights (higher = shown first)
  INSIGHT_PRIORITY = {
    time_saved: 100,
    code_contribution: 90,
    task_velocity: 80,
    token_efficiency: 70
  }.freeze

  # Minimum data thresholds before showing insights
  INSIGHT_THRESHOLDS = {
    time_saved: { minutes: 5 },
    code_contribution: { lines: 10 },
    task_velocity: { tasks: 1 },
    token_efficiency: { tokens: 1000 }
  }.freeze

  def initialize(user:, project: nil)
    @user = user
    @project = project
  end

  # Returns prioritized insights for the dashboard
  # Filters based on onboarding stage and available data
  # @param limit [Integer] Maximum number of insights to return
  # @return [Array<Hash>] Ordered list of insight hashes
  def dashboard_insights(limit: 4)
    return [] unless @user

    insights = []

    INSIGHT_TYPES.each do |type|
      insight = build_insight(type)
      insights << insight if insight && should_show_insight?(type, insight)
    end

    # Sort by priority and limit
    insights.sort_by { |i| -INSIGHT_PRIORITY[i[:type]] }.first(limit)
  end

  # Mark a specific insight as seen
  # @param key [String, Symbol] The insight key (e.g., :time_saved_intro)
  def mark_insight_seen(key)
    onboarding_progress.mark_insight_seen!(key.to_s)
  end

  # Get detailed time saved summary
  # @param period [Symbol] :day, :week, :month, :all
  # @return [Hash] Time saved statistics
  def time_saved_summary(period: :week)
    since = period_to_date(period)
    metrics = base_metrics.time_saved.since(since)

    total_saved = metrics.sum { |m| m.metric_data["time_saved_minutes"].to_i }
    total_ai_time = metrics.sum { |m| m.metric_data["ai_time_ms"].to_i } / 60_000.0
    sessions = metrics.count

    {
      total_saved_minutes: total_saved,
      total_saved_hours: (total_saved / 60.0).round(2),
      ai_time_minutes: total_ai_time.round(2),
      efficiency_ratio: calculate_efficiency_ratio(total_saved, total_ai_time),
      sessions:,
      period:,
      since:
    }
  end

  # Get detailed code contribution summary
  # @param period [Symbol] :day, :week, :month, :all
  # @return [Hash] Code contribution statistics
  def code_contribution_summary(period: :week)
    since = period_to_date(period)
    metrics = base_metrics.code_contributions.since(since)

    {
      lines_added: metrics.sum { |m| m.metric_data["lines_added"].to_i },
      lines_removed: metrics.sum { |m| m.metric_data["lines_removed"].to_i },
      net_lines: metrics.sum { |m| m.metric_data["net_lines"].to_i },
      files_changed: metrics.sum { |m| m.metric_data["files_changed"].to_i },
      commits: metrics.sum { |m| m.metric_data["commits"].to_i },
      sessions: metrics.count,
      period:,
      since:
    }
  end

  # Get detailed task velocity summary
  # @param period [Symbol] :day, :week, :month, :all
  # @return [Hash] Task velocity statistics
  def task_velocity_summary(period: :week)
    since = period_to_date(period)
    metrics = base_metrics.task_velocity.since(since)

    total_completed = metrics.sum { |m| m.metric_data["tasks_completed"].to_i }
    total_created = metrics.sum { |m| m.metric_data["tasks_created"].to_i }
    days = [(Time.current - since) / 1.day, 1].max

    {
      tasks_completed: total_completed,
      tasks_created: total_created,
      completion_rate: total_created.positive? ? (total_completed.to_f / total_created).round(3) : 0,
      velocity_per_day: (total_completed / days).round(2),
      sessions: metrics.count,
      period:,
      since:
    }
  end

  # Get detailed token efficiency summary
  # @param period [Symbol] :day, :week, :month, :all
  # @return [Hash] Token usage statistics
  def token_efficiency_summary(period: :week)
    since = period_to_date(period)
    metrics = base_metrics.token_efficiency.since(since)

    total_tokens = metrics.sum { |m| m.metric_data["total_tokens"].to_i }
    total_cost = metrics.sum { |m| m.metric_data["estimated_cost_usd"].to_f }

    {
      total_tokens:,
      input_tokens: metrics.sum { |m| m.metric_data["input_tokens"].to_i },
      output_tokens: metrics.sum { |m| m.metric_data["output_tokens"].to_i },
      estimated_cost_usd: total_cost.round(4),
      cost_per_1k_tokens: total_tokens.positive? ? ((total_cost / total_tokens) * 1000).round(4) : 0,
      sessions: metrics.count,
      period:,
      since:
    }
  end

  # Get aggregated summary of all metrics
  # @param period [Symbol] :day, :week, :month, :all
  # @return [Hash] Combined metrics summary
  def full_summary(period: :week)
    {
      time_saved: time_saved_summary(period:),
      code_contribution: code_contribution_summary(period:),
      task_velocity: task_velocity_summary(period:),
      token_efficiency: token_efficiency_summary(period:),
      onboarding: onboarding_summary
    }
  end

  # Get onboarding progress summary
  # @return [Hash] Onboarding progress data
  def onboarding_summary
    progress = onboarding_progress
    {
      stage: progress.current_stage_key,
      progress_percentage: progress.progress_percentage,
      insights_seen: progress.insights_seen,
      milestones_completed: progress.milestones_completed,
      complete: progress.onboarding_complete?
    }
  end

  private

  def onboarding_progress
    @onboarding_progress ||= @user.onboarding_progress || @user.create_onboarding_progress!
  end

  def base_metrics
    if @project
      @project.ai_productivity_metrics
    else
      @user.ai_productivity_metrics
    end
  end

  def build_insight(type)
    summary = send("#{type}_summary")
    return nil if summary.nil? || summary.empty?

    intro_key = "#{type}_intro"
    seen = onboarding_progress.insight_seen?(intro_key)

    {
      type:,
      title: insight_title(type),
      description: insight_description(type, summary),
      summary:,
      intro_key:,
      seen:,
      has_data: has_sufficient_data?(type, summary),
      detail_path: "/dashboard/insights/#{type}"
    }
  end

  def should_show_insight?(type, insight)
    # Always show if data is available, even if seen
    insight[:has_data]
  end

  def has_sufficient_data?(type, summary)
    threshold = INSIGHT_THRESHOLDS[type]
    return true unless threshold

    case type
    when :time_saved
      summary[:total_saved_minutes].to_i >= threshold[:minutes]
    when :code_contribution
      (summary[:lines_added].to_i + summary[:lines_removed].to_i) >= threshold[:lines]
    when :task_velocity
      summary[:tasks_completed].to_i >= threshold[:tasks]
    when :token_efficiency
      summary[:total_tokens].to_i >= threshold[:tokens]
    else
      true
    end
  end

  def insight_title(type)
    {
      time_saved: "Time Saved by AI",
      code_contribution: "Code Contributions",
      task_velocity: "Task Velocity",
      token_efficiency: "Token Usage"
    }[type]
  end

  def insight_description(type, summary)
    case type
    when :time_saved
      hours = summary[:total_saved_hours]
      if hours >= 1
        "You've saved approximately #{hours.round(1)} hours this week"
      else
        "You've saved approximately #{summary[:total_saved_minutes]} minutes this week"
      end
    when :code_contribution
      "#{summary[:lines_added]} lines added, #{summary[:commits]} commits this week"
    when :task_velocity
      "#{summary[:tasks_completed]} tasks completed at #{summary[:velocity_per_day]}/day"
    when :token_efficiency
      cost = summary[:estimated_cost_usd]
      if cost > 0
        "#{format_number(summary[:total_tokens])} tokens used ($#{cost.round(2)})"
      else
        "#{format_number(summary[:total_tokens])} tokens used this week"
      end
    end
  end

  def period_to_date(period)
    case period.to_sym
    when :day then 1.day.ago
    when :week then 7.days.ago
    when :month then 30.days.ago
    when :all then 10.years.ago
    else 7.days.ago
    end
  end

  def calculate_efficiency_ratio(saved_minutes, ai_minutes)
    return 0 if ai_minutes.zero?
    (saved_minutes / ai_minutes).round(2)
  end

  def format_number(num)
    return "0" if num.nil? || num.zero?
    return num.to_s if num < 1000

    if num >= 1_000_000
      "#{(num / 1_000_000.0).round(1)}M"
    elsif num >= 1000
      "#{(num / 1000.0).round(1)}K"
    else
      num.to_s
    end
  end
end
