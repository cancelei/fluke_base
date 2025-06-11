class Project < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :agreements, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_many :mentors, through: :agreements, source: :mentor

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :stage, presence: true
  validates :collaboration_type, inclusion: { in: [ "mentor", "co_founder", "both", nil ] }
  validates :repository_url, format: {
    with: /(^$|^https?:\/\/github\.com\/[^\/]+\/[^\/]+$|^[^\/\s]+\/[^\/\s]+$)/,
    message: "must be a valid GitHub repository URL or in the format username/repository"
  }, allow_blank: true

  # Default values and lifecycle hooks
  before_save :set_defaults

  # Project stages
  IDEA = "idea"
  PROTOTYPE = "prototype"
  LAUNCHED = "launched"
  SCALING = "scaling"

  # Collaboration types
  SEEKING_MENTOR = "mentor"
  SEEKING_COFOUNDER = "co_founder"
  SEEKING_BOTH = "both"

  # Public field options
  PUBLIC_FIELD_OPTIONS = %w[
    name description stage category current_stage
    target_market funding_status team_size collaboration_type
  ]

  # Scopes
  scope :ideas, -> { where(stage: IDEA) }
  scope :prototypes, -> { where(stage: PROTOTYPE) }
  scope :launched, -> { where(stage: LAUNCHED) }
  scope :scaling, -> { where(stage: SCALING) }

  scope :seeking_mentor, -> { where("collaboration_type = ? OR collaboration_type = ?", SEEKING_MENTOR, SEEKING_BOTH) }
  scope :seeking_cofounder, -> { where("collaboration_type = ? OR collaboration_type = ?", SEEKING_COFOUNDER, SEEKING_BOTH) }

  # Helper methods for checking collaboration type
  def seeking_mentor?
    collaboration_type == SEEKING_MENTOR || collaboration_type == SEEKING_BOTH
  end

  def seeking_cofounder?
    collaboration_type == SEEKING_COFOUNDER || collaboration_type == SEEKING_BOTH
  end

  # Public field methods - data access only, presentation logic moved to helper
  def field_public?(field_name)
    return false unless public_fields.is_a?(Array)
    public_fields.include?(field_name.to_s)
  end

  def visible_to_user?(field_name, user)
    return true if user && (user_id == user.id)
    return true if field_public?(field_name)
    return true if user && agreements.exists?(other_party_id: user.id)
    false
  end

  # Methods
  def progress_percentage
    return 0 if milestones.empty?

    completed = milestones.where(status: "completed").count
    (completed.to_f / milestones.count * 100).round
  end

  # Methods to check current stage
  def idea?
    stage == IDEA
  end

  def prototype?
    stage == PROTOTYPE
  end

  def launched?
    stage == LAUNCHED
  end

  def scaling?
    stage == SCALING
  end

  private

  def set_defaults
    self.stage ||= IDEA
    self.current_stage ||= stage.humanize if stage.present?
    self.collaboration_type ||= SEEKING_MENTOR
    self.public_fields ||= []
  end
end
