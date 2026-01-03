# frozen_string_literal: true

# Read-only model for the ai_productivity_stats materialized view.
#
# Provides aggregated AI productivity statistics per project,
# refreshed periodically for dashboard performance.
#
# == Schema Information
#
# Table name: ai_productivity_stats
#
#  active_days              :bigint
#  avg_task_completion_rate :decimal(, )
#  calculated_at            :timestamptz
#  first_activity_at        :datetime
#  last_activity_at         :datetime
#  total_commits            :bigint
#  total_estimated_cost     :decimal(, )
#  total_files_changed      :bigint
#  total_lines_added        :bigint
#  total_lines_removed      :bigint
#  total_tasks_completed    :bigint
#  total_time_saved_minutes :decimal(, )
#  total_tokens_used        :bigint
#  project_id               :bigint           primary key
#
# Indexes
#
#  idx_ai_productivity_stats_project  (project_id) UNIQUE
#
class AiProductivityStat < ApplicationRecord
  self.table_name = "ai_productivity_stats"
  self.primary_key = "project_id"

  belongs_to :project

  # Materialized view is read-only
  def readonly?
    true
  end

  # Refresh the materialized view
  def self.refresh!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY ai_productivity_stats")
  rescue ActiveRecord::StatementInvalid => e
    # Fall back to non-concurrent refresh if no unique index
    if e.message.include?("cannot refresh")
      connection.execute("REFRESH MATERIALIZED VIEW ai_productivity_stats")
    else
      raise
    end
  end

  # Check if refresh is needed (older than threshold)
  def self.needs_refresh?(threshold: 1.hour)
    stat = first
    return true unless stat&.calculated_at

    stat.calculated_at < threshold.ago
  end

  # Refresh if needed
  def self.refresh_if_stale!(threshold: 1.hour)
    refresh! if needs_refresh?(threshold: threshold)
  end

  # Time saved in hours
  def time_saved_hours
    (total_time_saved_minutes || 0) / 60.0
  end

  # Net lines of code
  def net_lines
    (total_lines_added || 0) - (total_lines_removed || 0)
  end

  # Calculate an efficiency score (0-100)
  def efficiency_score
    return 0 unless total_tasks_completed.to_i.positive?

    # Components:
    # - Task completion rate (40%)
    # - Time saved factor (30%)
    # - Code contribution factor (30%)

    completion_factor = [avg_task_completion_rate || 0, 1].min * 40
    time_factor = [time_saved_hours / 10.0, 1].min * 30
    code_factor = [net_lines.abs / 1000.0, 1].min * 30

    (completion_factor + time_factor + code_factor).round(1)
  end

  # Summary hash for API responses
  def as_summary
    {
      time_saved: {
        minutes: total_time_saved_minutes || 0,
        hours: time_saved_hours.round(2)
      },
      code_contribution: {
        lines_added: total_lines_added || 0,
        lines_removed: total_lines_removed || 0,
        net_lines: net_lines,
        files_changed: total_files_changed || 0,
        commits: total_commits || 0
      },
      task_velocity: {
        completed: total_tasks_completed || 0,
        completion_rate: (avg_task_completion_rate || 0).round(3)
      },
      token_usage: {
        total: total_tokens_used || 0,
        cost_usd: (total_estimated_cost || 0).round(4)
      },
      activity: {
        active_days: active_days || 0,
        first_activity: first_activity_at,
        last_activity: last_activity_at
      },
      efficiency_score: efficiency_score,
      calculated_at: calculated_at
    }
  end
end
