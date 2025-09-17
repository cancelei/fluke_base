FactoryBot.define do
  factory :agreement_participant do
    association :agreement
    association :user
    association :project
    user_role { "collaborator" }
    is_initiator { false }

    trait :initiator do
      is_initiator { true }
      user_role { "entrepreneur" }
    end

    trait :other_party do
      is_initiator { false }
      user_role { "mentor" }
    end

    trait :co_founder do
      user_role { "co_founder" }
    end

    trait :mentor do
      user_role { "mentor" }
    end

    trait :entrepreneur do
      user_role { "entrepreneur" }
    end
  end
end
