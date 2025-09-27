FactoryBot.define do
  factory :github_branch_log do
    association :github_branch
    association :github_log
  end
end
