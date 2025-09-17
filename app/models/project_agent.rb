class ProjectAgent < ApplicationRecord
  belongs_to :project

  # Validations
  validates :provider, presence: true, inclusion: { in: %w[openai anthropic] }
  validates :model, presence: true
  validate :validate_model_for_provider

  # Constants
  OPENAI_MODELS = %w[gpt-4 gpt-4-turbo gpt-3.5-turbo].freeze
  ANTHROPIC_MODELS = %w[claude-3-opus claude-3-sonnet claude-3-haiku].freeze

  # Default values
  before_validation :set_defaults, on: :create

  # Scopes
  scope :openai, -> { where(provider: "openai") }
  scope :anthropic, -> { where(provider: "anthropic") }

  def openai?
    provider == "openai"
  end

  def anthropic?
    provider == "anthropic"
  end

  def available_models
    case provider
    when "openai"
      OPENAI_MODELS
    when "anthropic"
      ANTHROPIC_MODELS
    else
      []
    end
  end

  private

  def set_defaults
    self.provider ||= "openai"
    self.model ||= default_model_for_provider
  end

  def default_model_for_provider
    case provider
    when "openai"
      "gpt-4"
    when "anthropic"
      "claude-3-sonnet"
    else
      "gpt-4"
    end
  end

  def validate_model_for_provider
    return unless provider.present? && model.present?

    unless available_models.include?(model)
      errors.add(:model, "#{model} is not a valid model for #{provider} provider")
    end
  end
end
