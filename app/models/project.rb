class Project < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :agreements, dependent: :destroy
  has_many :milestones, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :stage, presence: true
  validates :collaboration_type, inclusion: { in: [ "mentor", "co_founder", "both", nil ] }

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
  end
end
