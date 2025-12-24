# frozen_string_literal: true

FactoryBot.define do
  factory :github_app_installation do
    user
    sequence(:installation_id) { |n| "#{1000000 + n}" }
    account_login { user.github_username || "testuser" }
    account_type { "User" }
    repository_selection do
      {
        "selection" => "selected",
        "repositories" => [
          { "id" => 123, "full_name" => "testuser/testrepo", "private" => false }
        ]
      }
    end
    permissions { { "contents" => "read", "metadata" => "read" } }
    installed_at { Time.current }

    trait :all_repos do
      repository_selection do
        {
          "selection" => "all",
          "repositories" => []
        }
      end
    end

    trait :organization do
      account_type { "Organization" }
      account_login { "test-org" }
    end

    trait :multiple_repos do
      repository_selection do
        {
          "selection" => "selected",
          "repositories" => [
            { "id" => 123, "full_name" => "testuser/repo1", "private" => false },
            { "id" => 456, "full_name" => "testuser/repo2", "private" => true },
            { "id" => 789, "full_name" => "testuser/repo3", "private" => false }
          ]
        }
      end
    end
  end
end
