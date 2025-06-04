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
  scope :upcoming, -> { where("due_date > ?", Date.today).order(due_date: :asc) }

  # Check if milestone is completed
  def completed?
    status == COMPLETED
  end
end
