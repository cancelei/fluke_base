FactoryBot.define do
  factory :milestone do
    title { "Build MVP Feature" }
    description { "Build a basic MVP with core features that demonstrates the primary value proposition" }
    due_date { 2.weeks.from_now }
    status { "pending" }
    association :project

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :overdue do
      due_date { 1.week.ago }
    end
  end
end
