# frozen_string_literal: true

module FlukebaseConnect
  # Provides portfolio-level productivity analytics across all user projects.
  # Aggregates metrics from AiProductivityMetric to give power users (5-12 projects)
  # a holistic view of their AI productivity across their entire portfolio.
  class PortfolioAnalyticsService
    def initialize(user)
      @user = user
      @projects = user.accessible_projects
    end

    # Aggregate productivity metrics across all accessible projects
    def aggregate(period: 30)
      start_date = period.days.ago
      project_ids = @projects.pluck(:id)

      return empty_aggregate(period) if project_ids.empty?

      metrics = AiProductivityMetric.where(project_id: project_ids).since(start_date)

      {
        period_days: period,
        projects_count: @projects.count,
        projects_with_metrics: metrics.select(:project_id).distinct.count,
        totals: calculate_totals(metrics),
        averages: calculate_averages(metrics, @projects.count),
        by_metric_type: metrics_by_type(metrics)
      }
    end

    # Compare productivity across projects, returning ranked list
    def compare_projects(period: 30, sort_by: "time_saved", limit: 10)
      start_date = period.days.ago
      valid_sort_fields = %w[time_saved tasks_completed tokens_used sessions_count cost]
      sort_by = "time_saved" unless valid_sort_fields.include?(sort_by)

      project_metrics = @projects.map do |project|
        metrics = project.ai_productivity_metrics.since(start_date)
        build_project_comparison(project, metrics)
      end

      # Sort by the requested field (descending)
      sorted = project_metrics.sort_by { |p| -(p[sort_by.to_sym] || 0) }
      sorted.take(limit)
    end

    # Get time-series productivity trends
    def trends(period: 30, granularity: "daily")
      start_date = period.days.ago
      project_ids = @projects.pluck(:id)

      return [] if project_ids.empty?

      metrics = AiProductivityMetric.where(project_id: project_ids).since(start_date)

      case granularity
      when "weekly"
        group_by_week(metrics)
      else
        group_by_day(metrics)
      end
    end

    private

    def empty_aggregate(period)
      {
        period_days: period,
        projects_count: 0,
        projects_with_metrics: 0,
        totals: empty_totals,
        averages: empty_averages,
        by_metric_type: {}
      }
    end

    def calculate_totals(metrics)
      time_saved = AiProductivityMetric.aggregate_time_saved(metrics.time_saved)
      code = AiProductivityMetric.aggregate_code_contribution(metrics.code_contributions)
      tasks = AiProductivityMetric.aggregate_task_velocity(metrics.task_velocity)
      tokens = AiProductivityMetric.aggregate_token_efficiency(metrics.token_efficiency)

      {
        time_saved_minutes: time_saved[:total_time_saved_minutes] || 0,
        time_saved_hours: time_saved[:total_time_saved_hours] || 0,
        tasks_completed: tasks[:total_tasks_completed] || 0,
        commits: code[:total_commits] || 0,
        lines_added: code[:total_lines_added] || 0,
        lines_removed: code[:total_lines_removed] || 0,
        tokens_used: tokens[:total_tokens] || 0,
        estimated_cost_usd: tokens[:total_cost_usd] || 0,
        sessions_count: metrics.sessions.count
      }
    end

    def calculate_averages(metrics, projects_count)
      return empty_averages if projects_count.zero?

      totals = calculate_totals(metrics)

      {
        time_saved_per_project: (totals[:time_saved_minutes] / projects_count.to_f).round(1),
        tasks_per_project: (totals[:tasks_completed] / projects_count.to_f).round(1),
        sessions_per_project: (totals[:sessions_count] / projects_count.to_f).round(1),
        cost_per_project: (totals[:estimated_cost_usd] / projects_count.to_f).round(2)
      }
    end

    def metrics_by_type(metrics)
      {
        time_saved: AiProductivityMetric.aggregate_time_saved(metrics.time_saved),
        code_contribution: AiProductivityMetric.aggregate_code_contribution(metrics.code_contributions),
        task_velocity: AiProductivityMetric.aggregate_task_velocity(metrics.task_velocity),
        token_efficiency: AiProductivityMetric.aggregate_token_efficiency(metrics.token_efficiency)
      }
    end

    def build_project_comparison(project, metrics)
      time_saved = AiProductivityMetric.aggregate_time_saved(metrics.time_saved)
      tasks = AiProductivityMetric.aggregate_task_velocity(metrics.task_velocity)
      tokens = AiProductivityMetric.aggregate_token_efficiency(metrics.token_efficiency)

      {
        project_id: project.id,
        project_name: project.name,
        time_saved: time_saved[:total_time_saved_minutes]&.round(1) || 0,
        tasks_completed: tasks[:total_tasks_completed] || 0,
        tokens_used: tokens[:total_tokens] || 0,
        cost: tokens[:total_cost_usd] || 0,
        sessions_count: metrics.sessions.count
      }
    end

    def group_by_day(metrics)
      grouped = metrics.group_by { |m| m.period_start.to_date }

      grouped.keys.sort.map do |date|
        day_metrics = AiProductivityMetric.where(id: grouped[date].map(&:id))
        build_trend_point(date.iso8601, day_metrics)
      end
    end

    def group_by_week(metrics)
      grouped = metrics.group_by { |m| m.period_start.beginning_of_week.to_date }

      grouped.keys.sort.map do |week_start|
        week_metrics = AiProductivityMetric.where(id: grouped[week_start].map(&:id))
        build_trend_point(week_start.iso8601, week_metrics)
      end
    end

    def build_trend_point(period_label, metrics)
      time_saved = AiProductivityMetric.aggregate_time_saved(metrics.time_saved)
      tasks = AiProductivityMetric.aggregate_task_velocity(metrics.task_velocity)
      tokens = AiProductivityMetric.aggregate_token_efficiency(metrics.token_efficiency)

      {
        period: period_label,
        time_saved_minutes: time_saved[:total_time_saved_minutes]&.round(1) || 0,
        tasks_completed: tasks[:total_tasks_completed] || 0,
        tokens_used: tokens[:total_tokens] || 0,
        sessions_count: metrics.sessions.count
      }
    end

    def empty_totals
      {
        time_saved_minutes: 0,
        time_saved_hours: 0,
        tasks_completed: 0,
        commits: 0,
        lines_added: 0,
        lines_removed: 0,
        tokens_used: 0,
        estimated_cost_usd: 0,
        sessions_count: 0
      }
    end

    def empty_averages
      {
        time_saved_per_project: 0,
        tasks_per_project: 0,
        sessions_per_project: 0,
        cost_per_project: 0
      }
    end
  end
end
