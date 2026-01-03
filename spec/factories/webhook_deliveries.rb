# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_deliveries
#
#  id                      :bigint           not null, primary key
#  attempt_count           :integer          default(0), not null
#  delivered_at            :datetime
#  event_type              :string           not null
#  idempotency_key         :string           not null
#  next_retry_at           :datetime
#  payload                 :jsonb            not null
#  response_body           :text
#  status_code             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  webhook_subscription_id :bigint           not null
#
# Indexes
#
#  idx_on_webhook_subscription_id_created_at_199b16efdc  (webhook_subscription_id,created_at)
#  index_webhook_deliveries_on_idempotency_key           (idempotency_key) UNIQUE
#  index_webhook_deliveries_on_next_retry_at             (next_retry_at) WHERE (delivered_at IS NULL)
#  index_webhook_deliveries_on_webhook_subscription_id   (webhook_subscription_id)
#
# Foreign Keys
#
#  fk_rails_...  (webhook_subscription_id => webhook_subscriptions.id)
#
FactoryBot.define do
  factory :webhook_delivery do
    webhook_subscription
    event_type { "env.updated" }
    payload do
      {
        event: "env.updated",
        timestamp: Time.current.iso8601,
        project_id: webhook_subscription.project_id,
        data: { key: "TEST_VAR" }
      }
    end
    sequence(:idempotency_key) { |n| "delivery_#{n}_#{SecureRandom.hex(8)}" }
    attempt_count { 0 }

    trait :delivered do
      status_code { 200 }
      delivered_at { Time.current }
      attempt_count { 1 }
    end

    trait :failed do
      status_code { 500 }
      response_body { "Internal Server Error" }
      attempt_count { 1 }
    end

    trait :max_retries do
      attempt_count { WebhookDelivery::MAX_ATTEMPTS }
    end
  end
end
