# == Schema Information
#
# Table name: meetings
#
#  id                       :bigint           not null, primary key
#  description              :text
#  end_time                 :datetime         not null
#  start_time               :datetime         not null
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  agreement_id             :bigint           not null
#  google_calendar_event_id :string
#
# Indexes
#
#  index_meetings_on_agreement_id                 (agreement_id)
#  index_meetings_on_agreement_id_and_start_time  (agreement_id,start_time)
#  index_meetings_on_end_time                     (end_time)
#  index_meetings_on_google_calendar_event_id     (google_calendar_event_id)
#  index_meetings_on_start_time                   (start_time)
#
# Foreign Keys
#
#  fk_rails_...  (agreement_id => agreements.id)
#
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
