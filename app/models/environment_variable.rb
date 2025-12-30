# frozen_string_literal: true

# == Schema Information
#
# Table name: environment_variables
#
#  id               :bigint           not null, primary key
#  description      :text
#  environment      :string           default("development"), not null
#  example_value    :text
#  is_required      :boolean          default(FALSE), not null
#  is_secret        :boolean          default(FALSE), not null
#  key              :string           not null
#  validation_regex :string
#  value_ciphertext :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  created_by_id    :bigint           not null
#  project_id       :bigint           not null
#  updated_by_id    :bigint
#
# Indexes
#
#  idx_env_vars_project_env_key                               (project_id,environment,key) UNIQUE
#  index_environment_variables_on_created_by_id               (created_by_id)
#  index_environment_variables_on_project_id                  (project_id)
#  index_environment_variables_on_project_id_and_environment  (project_id,environment)
#  index_environment_variables_on_updated_by_id               (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class EnvironmentVariable < ApplicationRecord
  include WebhookDispatchable

  belongs_to :project
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User", optional: true

  # Webhook configuration
  webhook_events create: "env.created",
                 update: "env.updated",
                 destroy: "env.deleted"

  # Encrypt the value at rest
  encrypts :value_ciphertext

  # Valid environments
  ENVIRONMENTS = %w[development staging production].freeze

  # Patterns that indicate a secret value
  SECRET_PATTERNS = %w[
    _KEY _SECRET _TOKEN _PASSWORD _CREDENTIAL
    DATABASE_URL REDIS_URL API_KEY SECRET_KEY
  ].freeze

  # Validations
  validates :key, presence: true,
                  format: {
                    with: /\A[A-Z][A-Z0-9_]*\z/,
                    message: "must be uppercase letters, numbers, and underscores, starting with a letter"
                  },
                  uniqueness: { scope: [:project_id, :environment] }
  validates :environment, presence: true, inclusion: { in: ENVIRONMENTS }
  validate :validate_value_format, if: :validation_regex?

  # Scopes
  scope :for_environment, ->(env) { where(environment: env) }
  scope :required, -> { where(is_required: true) }
  scope :secrets, -> { where(is_secret: true) }

  # Callbacks
  before_save :auto_detect_secret

  # Store value (alias for value_ciphertext=)
  def value=(plaintext)
    self.value_ciphertext = plaintext
  end

  # Retrieve decrypted value
  def decrypted_value
    value_ciphertext
  end

  # Retrieve value (alias)
  def value
    decrypted_value
  end

  # Masked value for display
  def masked_value
    return nil if value_ciphertext.blank?

    if is_secret
      "***REDACTED***"
    else
      value_ciphertext
    end
  end

  # Check if this key looks like a secret based on naming patterns
  def looks_like_secret?
    key_upper = key.to_s.upcase
    SECRET_PATTERNS.any? { |pattern| key_upper.include?(pattern) }
  end

  # Webhook payload (never expose actual secret values)
  def webhook_payload
    {
      id: id,
      key: key,
      environment: environment,
      description: description,
      is_secret: is_secret,
      is_required: is_required,
      value_changed: value_ciphertext.present?,
      project_id: project_id
    }
  end

  private

  # Validate value against regex if provided
  def validate_value_format
    return if value_ciphertext.blank? || validation_regex.blank?

    regex = Regexp.new(validation_regex)
    unless value_ciphertext.match?(regex)
      errors.add(:value, "does not match required format")
    end
  rescue RegexpError
    errors.add(:validation_regex, "is not a valid regular expression")
  end

  # Auto-detect if this should be marked as a secret
  def auto_detect_secret
    self.is_secret = true if !is_secret && looks_like_secret?
  end
end
