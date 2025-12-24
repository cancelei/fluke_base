# == Schema Information
#
# Table name: time_logs
#
#  id           :bigint           not null, primary key
#  description  :text
#  ended_at     :datetime
#  hours_spent  :decimal(10, 2)   default(0.0)
#  manual_entry :boolean          default(FALSE)
#  started_at   :datetime         not null
#  status       :string           default("in_progress")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  milestone_id :bigint
#  project_id   :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_time_logs_on_milestone_id                 (milestone_id)
#  index_time_logs_on_project_id_and_milestone_id  (project_id,milestone_id)
#  index_time_logs_on_project_id_and_user_id       (project_id,user_id)
#  index_time_logs_on_started_at                   (started_at)
#  index_time_logs_on_status                       (status)
#  index_time_logs_on_user_id                      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (milestone_id => milestones.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :time_log do
    association :project
    association :user
    association :milestone

    started_at { 2.hours.ago }
    ended_at { 1.hour.ago }
    description { "Working on project development" }
    hours_spent { 1.0 }
    status { "completed" }
    manual_entry { false }

    # Active time log (in progress)
    trait :active do
      ended_at { nil }
      hours_spent { nil }
      status { "in_progress" }
    end

    # Manual entry time log
    trait :manual do
      manual_entry { true }
      description { "Manual time entry for development work" }
    end

    # Long time log
    trait :long_session do
      started_at { 8.hours.ago }
      ended_at { 4.hours.ago }
      hours_spent { 4.0 }
    end

    # Recent time log
    trait :recent do
      started_at { 30.minutes.ago }
      ended_at { 5.minutes.ago }
      hours_spent { 0.42 }
    end

    # Time log without milestone (manual entry)
    trait :without_milestone do
      milestone { nil }
      manual_entry { true }
      description { "General project work - no specific milestone" }
    end

    # Time log with specific hours
    trait :with_hours do |hours = 2.0|
      transient do
        hours_to_log { hours }
      end

      started_at { hours_to_log.hours.ago }
      ended_at { Time.current }
      hours_spent { hours_to_log }
    end
  end
end
