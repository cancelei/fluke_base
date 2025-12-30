# frozen_string_literal: true

FactoryBot.define do
  factory :environment_variable do
    association :project
    association :created_by, factory: :user
    key { "TEST_#{SecureRandom.hex(4).upcase}" }
    environment { "development" }
    value_ciphertext { "test_value" }
    is_secret { false }
    is_required { false }

    trait :secret do
      is_secret { true }
      key { "SECRET_KEY_#{SecureRandom.hex(4).upcase}" }
    end

    trait :required do
      is_required { true }
    end

    trait :production do
      environment { "production" }
    end

    trait :staging do
      environment { "staging" }
    end
  end
end
