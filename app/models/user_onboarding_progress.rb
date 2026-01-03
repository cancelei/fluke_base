# frozen_string_literal: true

# Tracks user onboarding progress for AI productivity insights.
#
# Implements progressive disclosure by tracking which insights
# the user has seen and their overall onboarding stage.
#
# == Schema Information
#
# Table name: user_onboarding_progress
#
#  id                      :bigint           not null, primary key
#  first_ai_session_at     :datetime
#  first_task_completed_at :datetime
#  insights_seen           :jsonb            not null
#  milestones_completed    :jsonb            not null
#  onboarding_completed_at :datetime
#  onboarding_stage        :integer          default(0), not null
#  preferences             :jsonb            not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_user_onboarding_progress_on_onboarding_stage  (onboarding_stage)
#  index_user_onboarding_progress_on_user_id           (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserOnboardingProgress < ApplicationRecord
  self.table_name = "user_onboarding_progress"

  belongs_to :user

  ONBOARDING_STAGES = {
    new_user: 0,
    first_connection: 1,
    first_ai_session: 2,
    first_task_completed: 3,
    insights_explored: 4,
    onboarding_complete: 5
  }.freeze

  INSIGHT_KEYS = %w[
    time_saved_intro
    code_contribution_intro
    task_velocity_intro
    token_efficiency_intro
    weekly_summary
    monthly_review
  ].freeze

  MILESTONE_KEYS = %w[
    connected_flukebase
    first_ai_session
    first_task_created
    first_task_completed
    viewed_all_insights
  ].freeze

  validates :onboarding_stage, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  # Scopes
  scope :incomplete, -> { where("onboarding_stage < ?", ONBOARDING_STAGES[:onboarding_complete]) }
  scope :complete, -> { where(onboarding_stage: ONBOARDING_STAGES[:onboarding_complete]) }
  scope :at_stage, ->(stage) { where(onboarding_stage: ONBOARDING_STAGES[stage] || stage) }

  # Mark an insight as seen
  def mark_insight_seen!(key)
    return if insight_seen?(key)

    update!(insights_seen: insights_seen + [key])
    check_insights_milestone!
  end

  # Check if an insight has been seen
  def insight_seen?(key)
    insights_seen.include?(key.to_s)
  end

  # Mark a milestone as completed
  def mark_milestone_completed!(key)
    return if milestone_completed?(key)

    update!(milestones_completed: milestones_completed + [key])
  end

  # Check if a milestone is completed
  def milestone_completed?(key)
    milestones_completed.include?(key.to_s)
  end

  # Advance to a specific stage
  def advance_stage!(stage_key)
    new_stage = ONBOARDING_STAGES[stage_key.to_sym]
    return unless new_stage
    return if new_stage <= onboarding_stage

    attrs = { onboarding_stage: new_stage }

    case stage_key.to_sym
    when :first_ai_session
      attrs[:first_ai_session_at] ||= Time.current
    when :first_task_completed
      attrs[:first_task_completed_at] ||= Time.current
    when :onboarding_complete
      attrs[:onboarding_completed_at] ||= Time.current
    end

    update!(attrs)
  end

  # Get current stage as symbol
  def current_stage_key
    ONBOARDING_STAGES.key(onboarding_stage) || :new_user
  end

  # Check if onboarding is complete
  def onboarding_complete?
    onboarding_stage >= ONBOARDING_STAGES[:onboarding_complete]
  end

  # Get insights not yet seen
  def unseen_insights
    INSIGHT_KEYS - insights_seen
  end

  # Get incomplete milestones
  def incomplete_milestones
    MILESTONE_KEYS - milestones_completed
  end

  # Calculate progress percentage
  def progress_percentage
    return 100 if onboarding_complete?

    # Weight: 40% stages, 30% insights, 30% milestones
    stage_progress = (onboarding_stage.to_f / ONBOARDING_STAGES[:onboarding_complete]) * 40
    insight_progress = (insights_seen.size.to_f / INSIGHT_KEYS.size) * 30
    milestone_progress = (milestones_completed.size.to_f / MILESTONE_KEYS.size) * 30

    (stage_progress + insight_progress + milestone_progress).round
  end

  # Get user preference
  def preference(key)
    preferences[key.to_s]
  end

  # Set user preference
  def set_preference!(key, value)
    update!(preferences: preferences.merge(key.to_s => value))
  end

  private

  # Check if user has seen all intro insights
  def check_insights_milestone!
    intro_insights = INSIGHT_KEYS.select { |k| k.end_with?("_intro") }
    if (intro_insights - insights_seen).empty?
      mark_milestone_completed!("viewed_all_insights")
      advance_stage!(:insights_explored)
    end
  end
end
