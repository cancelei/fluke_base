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
FactoryBot.define do
  factory :meeting do
    title { "Team Meeting" }
    description { "Weekly team sync" }
    start_time { 1.hour.from_now }
    end_time { 2.hours.from_now }
    association :agreement
    google_calendar_event_id { SecureRandom.uuid }
  end
end
