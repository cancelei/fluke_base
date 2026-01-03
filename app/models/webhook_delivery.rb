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
class WebhookDelivery < ApplicationRecord
  belongs_to :webhook_subscription

  # Retry configuration
  MAX_ATTEMPTS = 5
  RETRY_DELAYS = [1.minute, 5.minutes, 30.minutes, 2.hours, 24.hours].freeze

  # Validations
  validates :event_type, presence: true
  validates :payload, presence: true
  validates :idempotency_key, presence: true, uniqueness: true

  # Scopes
  scope :pending, -> { where(delivered_at: nil) }
  scope :delivered, -> { where.not(delivered_at: nil) }
  scope :failed, -> { pending.where("attempt_count >= ?", MAX_ATTEMPTS) }
  scope :retryable, -> { pending.where("attempt_count < ? AND (next_retry_at IS NULL OR next_retry_at <= ?)", MAX_ATTEMPTS, Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Check if delivery was successful
  def delivered?
    delivered_at.present?
  end

  # Check if delivery can be retried
  def retryable?
    !delivered? && attempt_count < MAX_ATTEMPTS
  end

  # Check if delivery has exhausted retries
  def failed?
    !delivered? && attempt_count >= MAX_ATTEMPTS
  end

  # Record a successful delivery
  def record_success!(status_code:, response_body: nil)
    update!(
      status_code:,
      response_body: response_body&.truncate(10_000),
      delivered_at: Time.current,
      attempt_count: attempt_count + 1
    )
    webhook_subscription.record_success!
  end

  # Record a failed delivery attempt
  def record_failure!(status_code: nil, response_body: nil)
    new_attempt_count = attempt_count + 1
    next_delay = RETRY_DELAYS[[new_attempt_count - 1, RETRY_DELAYS.length - 1].min]

    update!(
      status_code:,
      response_body: response_body&.truncate(10_000),
      attempt_count: new_attempt_count,
      next_retry_at: new_attempt_count < MAX_ATTEMPTS ? Time.current + next_delay : nil
    )

    webhook_subscription.record_failure! if new_attempt_count >= MAX_ATTEMPTS
  end

  # Get retry delay for current attempt
  def retry_delay
    RETRY_DELAYS[[attempt_count, RETRY_DELAYS.length - 1].min]
  end

  # Generate idempotency key for an event
  def self.generate_idempotency_key(subscription_id:, event_type:, resource_id:, timestamp:)
    data = "#{subscription_id}:#{event_type}:#{resource_id}:#{timestamp.to_i}"
    Digest::SHA256.hexdigest(data)
  end
end
