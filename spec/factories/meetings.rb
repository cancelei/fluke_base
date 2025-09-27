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
