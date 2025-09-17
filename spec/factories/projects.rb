FactoryBot.define do
  factory :project do
    name { "FlukeBase Project" }
    description { "A sample project for testing milestone AI enhancement features" }
    stage { "prototype" }
    association :user

    trait :idea_stage do
      stage { "idea" }
    end

    trait :launched do
      stage { "launched" }
    end

    trait :scaling do
      stage { "scaling" }
    end

    trait :seeking_mentor do
      collaboration_type { "mentor" }
    end

    trait :seeking_cofounder do
      collaboration_type { "co_founder" }
    end
  end
end
