class Milestone < ApplicationRecord
  belongs_to :project
  has_many :time_logs, dependent: :destroy
  has_many :milestone_enhancements, dependent: :destroy

  validates :title, :due_date, :status, presence: true

  # Statuses must match database constraint
  PENDING = "pending"
  IN_PROGRESS = "in_progress"
  COMPLETED = "completed"
  CANCELLED = "cancelled"

  scope :pending, -> { where(status: PENDING) }
  scope :in_progress, -> { where(status: IN_PROGRESS) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :not_completed, -> { where.not(status: COMPLETED) }
  scope :upcoming, -> { where("due_date > ?", Date.today).order(due_date: :asc) }

  def completed? = status == COMPLETED

  # Get the actual status based on time logs and explicit status
  def actual_status
    return COMPLETED if status == COMPLETED

    # If milestone has time logs from project owner or agreement participants, it's in progress
    if has_time_logs_from_authorized_users?
      IN_PROGRESS
    elsif status == IN_PROGRESS
      # Allow explicit "In Progress" status even without time logs
      IN_PROGRESS
    else
      PENDING
    end
  end

  def has_time_logs_from_authorized_users?
    return false if time_logs.empty?

    # Cache authorized user IDs to prevent repeated queries
    @authorized_user_ids ||= begin
      project_owner_id = project.user_id
      agreement_participant_ids = project.agreements.active
                                        .joins(:agreement_participants)
                                        .pluck("agreement_participants.user_id")
      [project_owner_id] + agreement_participant_ids
    end

    time_logs.exists?(user_id: @authorized_user_ids)
  end

  def in_progress? = actual_status == IN_PROGRESS
  def not_started? = actual_status == PENDING
  def pending? = actual_status == PENDING
  def latest_enhancement = milestone_enhancements.recent.first
  def enhancement_history = milestone_enhancements.recent.limit(10)
  def has_successful_enhancement? = milestone_enhancements.successful.exists?
  def can_be_enhanced? = description.present?
end
