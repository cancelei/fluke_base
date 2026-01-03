# frozen_string_literal: true

# == Schema Information
#
# Table name: browser_test_runs
#
#  id                   :bigint           not null, primary key
#  assertions           :json
#  completed_at         :datetime
#  duration_ms          :integer
#  results              :json
#  screenshot_base64    :text
#  started_at           :datetime
#  status               :string           default("pending"), not null
#  suite_name           :string
#  test_type            :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  cloudflare_worker_id :bigint           not null
#  project_id           :bigint
#  user_id              :bigint
#
# Indexes
#
#  index_browser_test_runs_on_cloudflare_worker_id  (cloudflare_worker_id)
#  index_browser_test_runs_on_created_at            (created_at)
#  index_browser_test_runs_on_project_id            (project_id)
#  index_browser_test_runs_on_status                (status)
#  index_browser_test_runs_on_test_type             (test_type)
#  index_browser_test_runs_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (cloudflare_worker_id => cloudflare_workers.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class BrowserTestRun < ApplicationRecord
  # =============================================================================
  # Constants
  # =============================================================================

  STATUSES = %w[pending running passed failed error cancelled].freeze
  TEST_TYPES = %w[smoke auth oauth security_session security_access security_escalation
                  form_project form_milestone form_agreement user_journey suite].freeze
  SUITE_NAMES = %w[smoke auth security forms full].freeze

  # =============================================================================
  # Relationships
  # =============================================================================

  belongs_to :project, optional: true
  belongs_to :cloudflare_worker
  belongs_to :user, optional: true

  # =============================================================================
  # Validations
  # =============================================================================

  validates :test_type, presence: true, inclusion: { in: TEST_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :suite_name, inclusion: { in: SUITE_NAMES }, allow_blank: true

  # =============================================================================
  # Scopes
  # =============================================================================

  scope :pending, -> { where(status: "pending") }
  scope :running, -> { where(status: "running") }
  scope :passed, -> { where(status: "passed") }
  scope :failed, -> { where(status: "failed") }
  scope :errored, -> { where(status: "error") }
  scope :completed, -> { where(status: %w[passed failed error]) }
  scope :by_type, ->(type) { where(test_type: type) }
  scope :by_project, ->(project_id) { where(project_id:) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }

  # =============================================================================
  # Instance Methods
  # =============================================================================

  # Status helpers
  def pending? = status == "pending"
  def running? = status == "running"
  def passed? = status == "passed"
  def failed? = status == "failed"
  def errored? = status == "error"
  def completed? = status.in?(%w[passed failed error])
  def in_progress? = status.in?(%w[pending running])

  # Mark as running
  def start!
    update!(status: "running", started_at: Time.current)
  end

  # Mark as completed with results
  def complete!(passed:, results: {}, assertions: [], screenshot: nil, duration: nil)
    update!(
      status: passed ? "passed" : "failed",
      results:,
      assertions:,
      screenshot_base64: screenshot,
      duration_ms: duration,
      completed_at: Time.current
    )
  end

  # Mark as error
  def error!(message)
    update!(
      status: "error",
      results: { error: message },
      completed_at: Time.current
    )
  end

  # Mark as cancelled
  def cancel!
    return unless in_progress?
    update!(status: "cancelled", completed_at: Time.current)
  end

  # Calculate duration if not set
  def calculated_duration_ms
    return duration_ms if duration_ms.present?
    return nil unless started_at && completed_at
    ((completed_at - started_at) * 1000).to_i
  end

  # Count passed/failed assertions
  def passed_assertions_count
    assertions&.count { |a| a["passed"] } || 0
  end

  def failed_assertions_count
    assertions&.count { |a| !a["passed"] } || 0
  end

  def total_assertions_count
    assertions&.size || 0
  end

  # Check if has screenshot
  def has_screenshot?
    screenshot_base64.present?
  end

  # API serialization
  def to_api_hash
    {
      id:,
      test_type:,
      suite_name:,
      status:,
      passed: passed?,
      results: results || {},
      assertions: assertions || [],
      total_assertions: total_assertions_count,
      passed_assertions: passed_assertions_count,
      failed_assertions: failed_assertions_count,
      has_screenshot: has_screenshot?,
      duration_ms: calculated_duration_ms,
      started_at: started_at&.iso8601,
      completed_at: completed_at&.iso8601,
      project_id:,
      project_name: project&.name,
      user_id:,
      user_name: user&.full_name,
      cloudflare_worker_id:,
      worker_name: cloudflare_worker&.name,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  # Detailed API response with screenshot
  def to_api_hash_with_screenshot
    to_api_hash.merge(screenshot_base64:)
  end

  # =============================================================================
  # Class Methods
  # =============================================================================

  # Get pass rate for a period
  def self.pass_rate(since: 7.days.ago)
    completed_runs = completed.where("created_at >= ?", since)
    return 0 if completed_runs.empty?

    (completed_runs.passed.count.to_f / completed_runs.count * 100).round(1)
  end

  # Get summary stats
  def self.summary_stats(since: 7.days.ago)
    runs = where("created_at >= ?", since)
    {
      total: runs.count,
      pending: runs.pending.count,
      running: runs.running.count,
      passed: runs.passed.count,
      failed: runs.failed.count,
      errored: runs.errored.count,
      pass_rate: pass_rate(since:)
    }
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[test_type suite_name status created_at started_at completed_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project cloudflare_worker user]
  end
end
