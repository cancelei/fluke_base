# frozen_string_literal: true

# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime
#  last_used_at :datetime
#  last_used_ip :string
#  name         :string           not null
#  prefix       :string(8)        not null
#  revoked_at   :datetime
#  scopes       :text             default([]), is an Array
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_prefix                  (prefix)
#  index_api_tokens_on_token_digest            (token_digest) UNIQUE
#  index_api_tokens_on_user_id                 (user_id)
#  index_api_tokens_on_user_id_and_revoked_at  (user_id,revoked_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ApiToken < ApplicationRecord
  belongs_to :user

  # Available scopes for API tokens
  SCOPES = %w[
    read:projects
    write:projects
    read:environment
    write:environment
    read:milestones
    read:agreements
    read:context
    read:plugins
    read:memories
    write:memories
    read:webhooks
    write:webhooks
    read:metrics
    write:metrics
    read:tasks
    write:tasks
    read:agents
    write:agents
  ].freeze

  # Default scopes for new tokens (read-only access)
  DEFAULT_SCOPES = %w[
    read:projects
    read:environment
    read:milestones
    read:context
  ].freeze

  # Token prefix for identification
  TOKEN_PREFIX = "fbk_"

  # Encrypt token digest for secure storage
  encrypts :token_digest, deterministic: true

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true
  validates :prefix, presence: true, length: { is: 8 }
  validates :scopes, presence: true
  validate :scopes_are_valid

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :for_user, ->(user) { where(user:) }

  # Result struct returned by generate_for
  GenerateResult = Struct.new(:token, :raw_token, :prefix, keyword_init: true)

  # Generate a new token for a user
  # Returns a GenerateResult with :token (the model), :raw_token (shown once), :prefix
  def self.generate_for(user, name:, scopes: DEFAULT_SCOPES, expires_in: nil)
    # Generate secure token: fbk_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
    raw_token = "#{TOKEN_PREFIX}#{SecureRandom.urlsafe_base64(32)}"
    prefix = raw_token[0, 8] # "fbk_xxxx"

    token = create!(
      user:,
      name:,
      token_digest: Digest::SHA256.hexdigest(raw_token),
      prefix:,
      scopes:,
      expires_at: expires_in ? Time.current + expires_in : nil
    )

    # Return the raw token (only shown once)
    GenerateResult.new(
      token:,
      raw_token:,
      prefix:
    )
  end

  # Find token by raw value
  def self.find_by_raw_token(raw_token)
    return nil unless raw_token&.start_with?(TOKEN_PREFIX)

    digest = Digest::SHA256.hexdigest(raw_token)
    active.find_by(token_digest: digest)
  end

  # Revoke this token
  def revoke!
    update!(revoked_at: Time.current)
  end

  # Check if token is revoked
  def revoked?
    revoked_at.present?
  end

  # Check if token is expired
  def expired?
    expires_at.present? && expires_at < Time.current
  end

  # Check if token is active (not revoked or expired)
  def active?
    !revoked? && !expired?
  end

  # Check if token has a specific scope
  def has_scope?(scope)
    scopes.include?(scope) || scopes.include?("*")
  end

  # Record usage of this token
  def record_usage!(ip_address)
    update_columns(
      last_used_at: Time.current,
      last_used_ip: ip_address
    )
  end

  private

  # Validate that all scopes are valid
  def scopes_are_valid
    invalid_scopes = scopes - SCOPES - ["*"]
    if invalid_scopes.any?
      errors.add(:scopes, "contains invalid scopes: #{invalid_scopes.join(', ')}")
    end
  end
end
