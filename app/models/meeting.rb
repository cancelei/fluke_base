class Meeting < ApplicationRecord
  # Relationships
  belongs_to :agreement

  # Validations
  validates :title, :start_time, :end_time, presence: true
  validate :end_time_after_start_time

  # Scopes
  scope :upcoming, -> { where("start_time > ?", Time.current).order(start_time: :asc) }
  scope :past, -> { where("end_time < ?", Time.current).order(start_time: :desc) }

  # Methods
  def duration_in_minutes
    ((end_time - start_time) / 60).to_i
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time

    if end_time <= start_time
      errors.add(:end_time, "must be after the start time")
    end
  end
end
