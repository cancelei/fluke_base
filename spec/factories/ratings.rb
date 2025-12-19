# frozen_string_literal: true

FactoryBot.define do
  factory :rating do
    association :rater, factory: :user
    association :rateable, factory: :user
    value { rand(1..5) }
    review { nil }

    trait :with_review do
      review { Faker::Lorem.paragraph }
    end

    trait :five_stars do
      value { 5 }
    end

    trait :four_stars do
      value { 4 }
    end

    trait :three_stars do
      value { 3 }
    end

    trait :two_stars do
      value { 2 }
    end

    trait :one_star do
      value { 1 }
    end
  end
end
