class TimeLog < ApplicationRecord
  # Relationships
  belongs_to :agreement
  belongs_to :milestone

  # Validations
  validates :started_at, presence: true
  validate :ended_at_after_started_at
  validates :hours_spent, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[in_progress completed] }

  
  # Status scopes
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :for_agreement, ->(agreement_id) { where(agreement_id: agreement_id) }
  scope :for_milestone, ->(milestone_id) { where(milestone_id: milestone_id) }

  # Callbacks
  before_save :calculate_hours_spent

  # Check if time log is completed
  def completed?
    status == 'completed'
  end

  # Mark as completed
  def complete!(end_time = Time.current)
    update(ended_at: end_time, status: 'completed')
  end

  # Calculate total hours spent on this time log
  def calculate_hours_spent
    return unless ended_at.present? && started_at.present?
    
    self.hours_spent = ((ended_at - started_at) / 1.hour).round(2)
  end

  private

  def ended_at_after_started_at
    return if ended_at.blank? || started_at.blank?
    
    if ended_at < started_at
      errors.add(:ended_at, "must be after the start time")
    end
  end
end
