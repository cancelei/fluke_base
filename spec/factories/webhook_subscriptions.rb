# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_subscriptions
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE), not null
#  callback_url    :string           not null
#  events          :text             default(["env.updated"]), is an Array
#  failure_count   :integer          default(0), not null
#  last_failure_at :datetime
#  last_success_at :datetime
#  secret          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  api_token_id    :bigint           not null
#  project_id      :bigint           not null
#
# Indexes
#
#  index_webhook_subscriptions_on_api_token_id           (api_token_id)
#  index_webhook_subscriptions_on_project_id_and_active  (project_id,active)
#
# Foreign Keys
#
#  webhook_subscriptions_api_token_id_fkey  (api_token_id => api_tokens.id)
#  webhook_subscriptions_project_id_fkey    (project_id => projects.id)
#
FactoryBot.define do
  factory :webhook_subscription do
    project
    api_token
    callback_url { "https://example.com/webhooks" }
    events { ["env.updated"] }
    active { true }
    failure_count { 0 }

    trait :inactive do
      active { false }
    end

    trait :unhealthy do
      failure_count { 5 }
    end

    trait :all_events do
      events { WebhookSubscription::EVENTS }
    end

    trait :env_events do
      events { %w[env.created env.updated env.deleted] }
    end

    trait :milestone_events do
      events { %w[milestone.created milestone.updated milestone.completed] }
    end

    trait :memory_events do
      events { %w[memory.created memory.updated memory.synced] }
    end
  end
end
