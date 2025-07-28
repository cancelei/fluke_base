class Milestone < ApplicationRecord
  # Relationships
  belongs_to :project
  has_many :time_logs, dependent: :destroy

  # Validations
  validates :title, :due_date, :status, presence: true

  # Milestone statuses
  NOT_STARTED = "not_started"
  IN_PROGRESS = "in_progress"
  COMPLETED = "completed"

  # Scopes
  scope :not_started, -> { where(status: NOT_STARTED) }
  scope :in_progress, -> { where(status: IN_PROGRESS) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :not_completed, -> { where.not(status: COMPLETED) }
  scope :upcoming, -> { where("due_date > ?", Date.today).order(due_date: :asc) }

  # Check if milestone is completed
  def completed?
    status == COMPLETED
  end

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
      NOT_STARTED
    end
  end

  # Check if milestone has time logs from authorized users (project owner or agreement participants)
  def has_time_logs_from_authorized_users?
    return false if time_logs.empty?

    project_owner_id = project.user_id
    agreement_participant_ids = project.agreements.active
                                      .joins(:agreement_participants)
                                      .pluck("agreement_participants.user_id")

    authorized_user_ids = [ project_owner_id ] + agreement_participant_ids

    time_logs.exists?(user_id: authorized_user_ids)
  end

  # Check if milestone is actually in progress (has time logs or explicit status)
  def in_progress?
    actual_status == IN_PROGRESS
  end

  # Check if milestone is not started
  def not_started?
    actual_status == NOT_STARTED
  end
end
