# frozen_string_literal: true

class CloudflareWorker < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  STATUSES = %w[unknown healthy unhealthy deploying error].freeze
  ENVIRONMENTS = %w[development staging production].freeze
  HEALTH_CHECK_TIMEOUT = 5.minutes

  # =============================================================================
  # Relationships
  # =============================================================================

  has_many :browser_test_runs, dependent: :destroy
  has_many :cloudflare_usage_metrics, dependent: :destroy

  # =============================================================================
  # Validations
  # =============================================================================

  validates :name, presence: true, uniqueness: true
  validates :account_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :environment, inclusion: { in: ENVIRONMENTS }
  validates :worker_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :active, -> { where(status: %w[healthy unknown]) }
  scope :healthy, -> { where(status: "healthy") }
  scope :unhealthy, -> { where(status: "unhealthy") }
  scope :by_environment, ->(env) { where(environment: env) }
  scope :for_current_env, -> { by_environment(Rails.env) }
  scope :needs_health_check, lambda {
    where("last_health_check_at IS NULL OR last_health_check_at < ?", HEALTH_CHECK_TIMEOUT.ago)
  }

  # =============================================================================
  # Instance Methods
  # =============================================================================

  # Status helpers
  def healthy? = status == "healthy"
  def unhealthy? = status == "unhealthy"
  def deploying? = status == "deploying"

  # Check if health check is stale
  def health_check_stale?
    last_health_check_at.nil? || last_health_check_at < HEALTH_CHECK_TIMEOUT.ago
  end

  # Mark as healthy after successful health check
  def mark_healthy!
    update!(status: "healthy", last_health_check_at: Time.current)
  end

  # Mark as unhealthy after failed health check
  def mark_unhealthy!
    update!(status: "unhealthy", last_health_check_at: Time.current)
  end

  # Mark as deploying
  def mark_deploying!
    update!(status: "deploying")
  end

  # Mark deployment complete
  def mark_deployed!(script_hash: nil)
    attrs = {
      status: "unknown",
      last_deployed_at: Time.current
    }
    attrs[:script_hash] = script_hash if script_hash.present?
    update!(attrs)
  end

  # Get usage for a date range
  def usage_between(from_date, to_date)
    cloudflare_usage_metrics
      .where(recorded_date: from_date..to_date)
      .order(recorded_date: :desc)
  end

  # Get today's usage
  def usage_today
    cloudflare_usage_metrics.find_by(recorded_date: Date.current, period_type: "daily")
  end

  # Total browser sessions for a period
  def total_sessions(since: 30.days.ago)
    cloudflare_usage_metrics
      .where(period_type: "daily")
      .where("recorded_date >= ?", since.to_date)
      .sum(:browser_sessions)
  end

  # API serialization
  def to_api_hash
    {
      id:,
      name:,
      account_id:,
      worker_url:,
      status:,
      environment:,
      script_hash:,
      last_deployed_at: last_deployed_at&.iso8601,
      last_health_check_at: last_health_check_at&.iso8601,
      health_check_stale: health_check_stale?,
      configuration: configuration || {},
      usage_today: usage_today&.to_api_hash,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # =============================================================================
  # Class Methods
  # =============================================================================

  # Find or create worker for current environment
  def self.default_worker
    find_by(environment: Rails.env) || create_default_for_environment(Rails.env)
  end

  # Create default worker configuration
  def self.create_default_for_environment(env)
    config = {
      "development" => {
        name: "flukebase-browser-tests",
        account_id: ENV.fetch("CLOUDFLARE_ACCOUNT_ID", "7f0d181aabe1f5c6ddb1733f9328a25a"),
        worker_url: ENV.fetch("CF_BROWSER_WORKER_URL", "https://flukebase-browser-tests.glauber-bannwart.workers.dev")
      },
      "staging" => {
        name: "flukebase-browser-tests-staging",
        account_id: ENV.fetch("CLOUDFLARE_ACCOUNT_ID", ""),
        worker_url: ENV.fetch("CF_BROWSER_WORKER_URL_STAGING", nil)
      },
      "production" => {
        name: "flukebase-browser-tests-prod",
        account_id: ENV.fetch("CLOUDFLARE_ACCOUNT_ID", ""),
        worker_url: ENV.fetch("CF_BROWSER_WORKER_URL_PRODUCTION", nil)
      }
    }

    create!(config[env].merge(environment: env))
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name environment status created_at last_deployed_at last_health_check_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[browser_test_runs cloudflare_usage_metrics]
  end
end
