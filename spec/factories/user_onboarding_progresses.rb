# frozen_string_literal: true

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
FactoryBot.define do
  factory :user_onboarding_progress do
    user
    onboarding_stage { 0 }
    insights_seen { [] }
    milestones_completed { [] }
    preferences { {} }

    trait :first_connection do
      onboarding_stage { 1 }
      milestones_completed { ["connected_flukebase"] }
    end

    trait :first_ai_session do
      onboarding_stage { 2 }
      milestones_completed { ["connected_flukebase", "first_ai_session"] }
      first_ai_session_at { 1.day.ago }
    end

    trait :first_task_completed do
      onboarding_stage { 3 }
      milestones_completed { ["connected_flukebase", "first_ai_session", "first_task_created", "first_task_completed"] }
      first_ai_session_at { 2.days.ago }
      first_task_completed_at { 1.day.ago }
    end

    trait :insights_explored do
      onboarding_stage { 4 }
      milestones_completed { UserOnboardingProgress::MILESTONE_KEYS }
      insights_seen { UserOnboardingProgress::INSIGHT_KEYS.select { |k| k.end_with?("_intro") } }
      first_ai_session_at { 1.week.ago }
      first_task_completed_at { 5.days.ago }
    end

    trait :complete do
      onboarding_stage { 5 }
      milestones_completed { UserOnboardingProgress::MILESTONE_KEYS }
      insights_seen { UserOnboardingProgress::INSIGHT_KEYS }
      first_ai_session_at { 1.month.ago }
      first_task_completed_at { 3.weeks.ago }
      onboarding_completed_at { 1.week.ago }
    end
  end
end
