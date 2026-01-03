# frozen_string_literal: true

FactoryBot.define do
  factory :wedo_task do
    project
    sequence(:task_id) { |n| "TASK-#{n.to_s.rjust(3, '0')}" }
    description { Faker::Lorem.sentence }
    status { "pending" }
    dependency { "AGENT_CAPABLE" }
    scope { "global" }
    priority { "normal" }
    version { 0 }

    trait :pending do
      status { "pending" }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
    end

    trait :blocked do
      status { "blocked" }
    end

    trait :user_required do
      dependency { "USER_REQUIRED" }
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :urgent do
      priority { "urgent" }
    end

    trait :with_tags do
      tags { %w[feature api] }
    end

    trait :with_external_id do
      sequence(:external_id) { |n| "ext-#{SecureRandom.uuid[0, 8]}-#{n}" }
    end

    trait :with_parent do
      association :parent_task, factory: :wedo_task
    end

    trait :with_assignee do
      association :assignee, factory: :user
    end

    trait :with_creator do
      association :created_by, factory: :user
      association :updated_by, factory: :user
    end
  end
end
