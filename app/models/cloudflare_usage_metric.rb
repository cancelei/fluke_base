# frozen_string_literal: true

# == Schema Information
#
# Table name: cloudflare_usage_metrics
#
#  id                   :bigint           not null, primary key
#  browser_sessions     :integer          default(0)
#  estimated_cost_usd   :decimal(10, 4)
#  execution_time_ms    :integer          default(0)
#  period_type          :string           default("daily"), not null
#  raw_metrics          :json
#  recorded_date        :date             not null
#  requests_count       :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  cloudflare_worker_id :bigint           not null
#
# Indexes
#
#  idx_cloudflare_usage_metrics_unique                     (cloudflare_worker_id,recorded_date,period_type) UNIQUE
#  index_cloudflare_usage_metrics_on_cloudflare_worker_id  (cloudflare_worker_id)
#  index_cloudflare_usage_metrics_on_recorded_date         (recorded_date)
#
# Foreign Keys
#
#  fk_rails_...  (cloudflare_worker_id => cloudflare_workers.id)
#
class CloudflareUsageMetric < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  PERIOD_TYPES = %w[daily weekly monthly].freeze

  # Pricing estimates (approximate, check Cloudflare pricing for actual)
  COST_PER_SESSION = 0.001  # $0.001 per browser session
  COST_PER_1K_REQUESTS = 0.50  # $0.50 per 1000 requests

  # =============================================================================
  # Relationships
  # =============================================================================

  belongs_to :cloudflare_worker

  # =============================================================================
  # Validations
  # =============================================================================

  validates :recorded_date, presence: true
  validates :period_type, inclusion: { in: PERIOD_TYPES }
  validates :cloudflare_worker_id, uniqueness: { scope: %i[recorded_date period_type] }

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :daily, -> { where(period_type: "daily") }
  scope :weekly, -> { where(period_type: "weekly") }
  scope :monthly, -> { where(period_type: "monthly") }
  scope :for_date, ->(date) { where(recorded_date: date) }
  scope :between_dates, ->(from, to) { where(recorded_date: from..to) }
  scope :recent, -> { order(recorded_date: :desc) }

  # =============================================================================
  # Callbacks
  # =============================================================================

  before_save :calculate_estimated_cost

  # =============================================================================
  # Instance Methods
  # =============================================================================

  # Calculate cost estimate based on usage
  def calculate_estimated_cost
    session_cost = (browser_sessions || 0) * COST_PER_SESSION
    request_cost = ((requests_count || 0) / 1000.0) * COST_PER_1K_REQUESTS
    self.estimated_cost_usd = session_cost + request_cost
  end

  # Execution time in seconds
  def execution_time_seconds
    return 0 if execution_time_ms.nil?
    execution_time_ms / 1000.0
  end

  # Average execution time per session
  def avg_execution_time_ms
    return 0 if browser_sessions.nil? || browser_sessions.zero?
    execution_time_ms.to_f / browser_sessions
  end

  # API serialization
  def to_api_hash
    {
      id:,
      cloudflare_worker_id:,
      recorded_date: recorded_date.to_s,
      period_type:,
      browser_sessions:,
      requests_count:,
      execution_time_ms:,
      execution_time_seconds:,
      avg_execution_time_ms: avg_execution_time_ms.round(2),
      estimated_cost_usd: estimated_cost_usd&.to_f&.round(4),
      raw_metrics: raw_metrics || {},
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # =============================================================================
  # Class Methods
  # =============================================================================

  # Upsert a daily metric (idempotent)
  def self.upsert_daily(worker:, date:, sessions: 0, requests: 0, execution_ms: 0, raw: {})
    metric = find_or_initialize_by(
      cloudflare_worker: worker,
      recorded_date: date,
      period_type: "daily"
    )

    metric.assign_attributes(
      browser_sessions: sessions,
      requests_count: requests,
      execution_time_ms: execution_ms,
      raw_metrics: raw
    )

    metric.save!
    metric
  end

  # Aggregate metrics for a period
  def self.aggregate_for_period(worker_id, from_date, to_date)
    metrics = where(cloudflare_worker_id: worker_id)
              .daily
              .between_dates(from_date, to_date)

    {
      period_start: from_date.to_s,
      period_end: to_date.to_s,
      days: metrics.count,
      total_sessions: metrics.sum(:browser_sessions),
      total_requests: metrics.sum(:requests_count),
      total_execution_time_ms: metrics.sum(:execution_time_ms),
      total_estimated_cost_usd: metrics.sum(:estimated_cost_usd)&.to_f&.round(4),
      avg_daily_sessions: metrics.average(:browser_sessions)&.round(1) || 0,
      avg_daily_requests: metrics.average(:requests_count)&.round(1) || 0
    }
  end

  # Get summary for dashboard
  def self.summary_for_worker(worker_id, since: 30.days.ago)
    aggregate_for_period(worker_id, since.to_date, Date.current)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[recorded_date period_type browser_sessions requests_count estimated_cost_usd]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cloudflare_worker]
  end
end
