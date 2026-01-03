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
class WebhookSubscription < ApplicationRecord
  belongs_to :project
  belongs_to :api_token
  has_many :webhook_deliveries, dependent: :destroy

  # Supported webhook events
  EVENTS = %w[
    env.created
    env.updated
    env.deleted
    milestone.created
    milestone.updated
    milestone.completed
    memory.created
    memory.updated
    memory.synced
    agreement.updated
  ].freeze

  # Validations
  validates :callback_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true
  validate :events_are_valid

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_event, ->(event) { where("? = ANY(events)", event) }
  scope :healthy, -> { where("failure_count < 5") }

  # Callbacks
  before_create :generate_secret

  # Check if subscription is healthy (not too many failures)
  def healthy?
    failure_count < 5
  end

  # Check if subscription should receive an event
  def subscribed_to?(event)
    events.include?(event) || events.include?("*")
  end

  # Record a successful delivery
  def record_success!
    update!(
      failure_count: 0,
      last_success_at: Time.current
    )
  end

  # Record a failed delivery
  def record_failure!
    update!(
      failure_count: failure_count + 1,
      last_failure_at: Time.current
    )

    # Auto-deactivate after too many failures
    update!(active: false) if failure_count >= 5
  end

  # Generate HMAC signature for payload
  def sign_payload(payload)
    return nil unless secret.present?

    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      secret,
      payload.to_json
    )
  end

  private

  def generate_secret
    self.secret ||= SecureRandom.hex(32)
  end

  def events_are_valid
    invalid_events = events - EVENTS - ["*"]
    if invalid_events.any?
      errors.add(:events, "contains invalid events: #{invalid_events.join(', ')}")
    end
  end
end
