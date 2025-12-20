class TimeLog < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :milestone, optional: true

  validates :started_at, presence: true
  validate :ended_at_after_started_at
  validates :hours_spent, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[in_progress completed] }
  validates :description, presence: true, if: -> { milestone_id.nil? }
  validate :start_time_not_in_future

  scope :not_manual, -> { where(manual_entry: false) }
  scope :manual, -> { where(manual_entry: true) }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :for_project, ->(project_id) { where(project_id:) }
  scope :for_milestone, ->(milestone_id) { where(milestone_id:) }
  scope :manual, -> { where(milestone_id: nil) }

  before_save :calculate_hours_spent
  after_update_commit :broadcast_time_log

  def completed? = status == "completed"
  def complete!(end_time = Time.current) = update(ended_at: end_time, status: "completed")

  def calculate_hours_spent
    return unless ended_at.present? && started_at.present?
    return if hours_spent.present?

    self.hours_spent = ((ended_at - started_at) / 1.hour).round(2)
  end

  def github_activities
    GithubLog.where(
      agreement_id:,
      commit_date: (started_at..ended_at)
    )
  end

  private

  def ended_at_after_started_at
    return if ended_at.blank? || started_at.blank?

    if ended_at < started_at
      errors.add(:ended_at, "must be after the start time")
    end
  end

  def start_time_not_in_future
    return if started_at.blank?

    if started_at > Time.zone.now
      errors.add(:started_at, "cannot be in the future")
    end
  end

  def broadcast_time_log
    return unless saved_change_to_status? && status == "completed"

    broadcast_replace_later_to(
      "milestone_#{milestone_id}_time_logs_started",
      target: "time_log_#{id}",
      partial: "time_logs/time_log",
      locals: { time_log: self }
    )
  end
end
