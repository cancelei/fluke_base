FactoryBot.define do
  factory :time_log do
    association :project
    association :user
    association :milestone

    started_at { 2.hours.ago }
    ended_at { 1.hour.ago }
    description { "Working on project development" }
    hours_spent { 1.0 }
    status { "completed" }
    manual_entry { false }

    # Active time log (in progress)
    trait :active do
      ended_at { nil }
      hours_spent { nil }
      status { "in_progress" }
    end

    # Manual entry time log
    trait :manual do
      manual_entry { true }
      description { "Manual time entry for development work" }
    end

    # Long time log
    trait :long_session do
      started_at { 8.hours.ago }
      ended_at { 4.hours.ago }
      hours_spent { 4.0 }
    end

    # Recent time log
    trait :recent do
      started_at { 30.minutes.ago }
      ended_at { 5.minutes.ago }
      hours_spent { 0.42 }
    end

    # Time log without milestone (manual entry)
    trait :without_milestone do
      milestone { nil }
      manual_entry { true }
      description { "General project work - no specific milestone" }
    end

    # Time log with specific hours
    trait :with_hours do |hours = 2.0|
      transient do
        hours_to_log { hours }
      end

      started_at { hours_to_log.hours.ago }
      ended_at { Time.current }
      hours_spent { hours_to_log }
    end
  end
end
