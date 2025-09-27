FactoryBot.define do
  factory :github_branch do
    association :project
    association :user
    sequence(:branch_name) { |n| n.even? ? "main" : "feature/test-#{n}" }
  end
end
