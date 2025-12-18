FactoryBot.define do
  factory :project_membership do
    association :project
    association :user
    role { "member" }
    accepted_at { Time.current }

    trait :pending do
      accepted_at { nil }
    end

    trait :owner do
      role { "owner" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :guest do
      role { "guest" }
    end
  end
end
