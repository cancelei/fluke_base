# frozen_string_literal: true

# Stores AI productivity metrics synced from flukebase_connect.
#
# Metrics include:
# - time_saved: Estimated time saved by AI assistance
# - code_contribution: Lines of code, commits attributed to AI
# - task_velocity: WeDo task completion rates
# - token_efficiency: Token usage and cost projections
#
# == Schema Information
#
# Table name: ai_productivity_metrics
#
#  id           :bigint           not null, primary key
#  metric_data  :jsonb            not null
#  metric_type  :string           not null
#  period_end   :datetime         not null
#  period_start :datetime         not null
#  period_type  :string           default("session"), not null
#  synced_at    :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string
#  project_id   :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  idx_on_project_id_metric_type_period_start_c4a679eb0b  (project_id,metric_type,period_start)
#  index_ai_productivity_metrics_on_external_id           (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_ai_productivity_metrics_on_metric_type           (metric_type)
#  index_ai_productivity_metrics_on_period_type           (period_type)
#  index_ai_productivity_metrics_on_project_id            (project_id)
#  index_ai_productivity_metrics_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class AiProductivityMetric < ApplicationRecord
  belongs_to :project
  belongs_to :user

  METRIC_TYPES = %w[time_saved code_contribution task_velocity token_efficiency].freeze
  PERIOD_TYPES = %w[session daily weekly monthly].freeze

  validates :metric_type, presence: true, inclusion: { in: METRIC_TYPES }
  validates :period_type, presence: true, inclusion: { in: PERIOD_TYPES }
  validates :period_start, presence: true
  validates :period_end, presence: true

  # Scopes by metric type
  scope :time_saved, -> { where(metric_type: "time_saved") }
  scope :code_contributions, -> { where(metric_type: "code_contribution") }
  scope :task_velocity, -> { where(metric_type: "task_velocity") }
  scope :token_efficiency, -> { where(metric_type: "token_efficiency") }

  # Scopes by period
  scope :for_period, ->(type) { where(period_type: type) }
  scope :sessions, -> { for_period("session") }
  scope :daily, -> { for_period("daily") }
  scope :weekly, -> { for_period("weekly") }
  scope :monthly, -> { for_period("monthly") }

  # Time-based scopes
  scope :since, ->(date) { where("period_start >= ?", date) }
  scope :before, ->(date) { where("period_end <= ?", date) }
  scope :this_week, -> { since(1.week.ago) }
  scope :this_month, -> { since(1.month.ago) }

  # Sync scopes
  scope :unsynced, -> { where(synced_at: nil) }
  scope :synced, -> { where.not(synced_at: nil) }

  # Aggregate metrics for a project
  def self.aggregate_for_project(project_id, since: 30.days.ago)
    metrics = where(project_id: project_id).since(since)

    {
      time_saved: aggregate_time_saved(metrics.time_saved),
      code_contribution: aggregate_code_contribution(metrics.code_contributions),
      task_velocity: aggregate_task_velocity(metrics.task_velocity),
      token_efficiency: aggregate_token_efficiency(metrics.token_efficiency),
      total_metrics: metrics.count,
      period_start: since,
      period_end: Time.current
    }
  end

  # Aggregate time saved metrics
  def self.aggregate_time_saved(metrics)
    return {} if metrics.empty?

    total_ai_time = 0
    total_human_time = 0
    total_saved = 0

    metrics.find_each do |m|
      data = m.metric_data
      total_ai_time += data["ai_time_ms"].to_i
      total_human_time += data["estimated_human_time_ms"].to_i
      total_saved += data["time_saved_ms"].to_i
    end

    {
      total_ai_time_ms: total_ai_time,
      total_estimated_human_time_ms: total_human_time,
      total_time_saved_ms: total_saved,
      total_time_saved_minutes: total_saved / 60_000.0,
      total_time_saved_hours: total_saved / 3_600_000.0,
      session_count: metrics.count
    }
  end

  # Aggregate code contribution metrics
  def self.aggregate_code_contribution(metrics)
    return {} if metrics.empty?

    total_commits = 0
    total_added = 0
    total_removed = 0
    total_files = 0

    metrics.find_each do |m|
      data = m.metric_data
      total_commits += data["total_commits"].to_i
      total_added += data["lines_added"].to_i
      total_removed += data["lines_removed"].to_i
      total_files += data["files_changed"].to_i
    end

    {
      total_commits: total_commits,
      total_lines_added: total_added,
      total_lines_removed: total_removed,
      total_files_changed: total_files,
      net_lines: total_added - total_removed
    }
  end

  # Aggregate task velocity metrics
  def self.aggregate_task_velocity(metrics)
    return {} if metrics.empty?

    total_completed = 0
    total_tasks = 0
    completion_rates = []

    metrics.find_each do |m|
      data = m.metric_data
      total_completed += data["completed_count"].to_i
      total_tasks += data["total_tasks"].to_i
      completion_rates << data["completion_rate"].to_f if data["completion_rate"]
    end

    avg_completion_rate = completion_rates.empty? ? 0 : completion_rates.sum / completion_rates.size

    {
      total_tasks_completed: total_completed,
      total_tasks_tracked: total_tasks,
      avg_completion_rate: avg_completion_rate.round(3),
      session_count: metrics.count
    }
  end

  # Aggregate token efficiency metrics
  def self.aggregate_token_efficiency(metrics)
    return {} if metrics.empty?

    total_tokens = 0
    total_input = 0
    total_output = 0
    total_cost = 0

    metrics.find_each do |m|
      data = m.metric_data
      total_tokens += data["total_tokens"].to_i
      total_input += data["input_tokens"].to_i
      total_output += data["output_tokens"].to_i
      total_cost += data["estimated_cost_usd"].to_f
    end

    {
      total_tokens: total_tokens,
      total_input_tokens: total_input,
      total_output_tokens: total_output,
      total_cost_usd: total_cost.round(4),
      session_count: metrics.count
    }
  end

  # Helper to extract specific metric value
  def value(key)
    metric_data[key.to_s]
  end

  # Time saved in hours
  def time_saved_hours
    (metric_data["time_saved_ms"].to_i / 3_600_000.0).round(2)
  end

  # Efficiency ratio
  def efficiency_ratio
    metric_data["efficiency_ratio"]&.to_f || 1.0
  end
end
