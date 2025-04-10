FactoryBot.define do
  factory :meeting do
    title { "MyString" }
    description { "MyText" }
    start_time { "2025-04-09 10:37:40" }
    end_time { "2025-04-09 10:37:40" }
    agreement { nil }
    google_calendar_event_id { "MyString" }
  end
end
