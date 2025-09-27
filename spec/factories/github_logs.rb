FactoryBot.define do
  factory :github_log do
    association :project
    user { nil } # Allow nil for unregistered users
    sequence(:commit_sha) { |n| "deadbeef#{n.to_s(16).rjust(4, '0')}" }
    commit_message { 'Test commit message' }
    lines_added { 0 }
    lines_removed { 0 }
    commit_date { Time.current }
    commit_url { 'https://example.com/commit' }
    unregistered_user_name { nil }

    trait :with_user do
      association :user
    end

    trait :unregistered do
      user { nil }
      unregistered_user_name { 'unregistered_user' }
    end
  end
end
