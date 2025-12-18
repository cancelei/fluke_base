FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "John" }
    last_name { "Doe" }

    trait :alice do
      first_name { "Alice" }
      last_name { "Smith" }
      email { "alice.smith@example.com" }
    end

    trait :bob do
      first_name { "Bob" }
      last_name { "Johnson" }
      email { "bob.johnson@example.com" }
      years_of_experience { 10.0 }
    end
  end
end
