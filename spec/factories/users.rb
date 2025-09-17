FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "John" }
    last_name { "Doe" }
    onboarded { true }

    trait :entrepreneur do
      first_name { "Alice" }
      last_name { "Entrepreneur" }
      email { "alice.entrepreneur@example.com" }
    end

    trait :mentor do
      first_name { "Bob" }
      last_name { "Mentor" }
      email { "bob.mentor@example.com" }
      years_of_experience { 10.0 }
    end
  end
end
