# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_productivity_metrics
#
#  id           :bigint           not null, primary key
#  metric_data  :jsonb            not null
#  metric_type  :string           not null
#  period_end   :datetime         not null
#  period_start :datetime         not null
#  period_type  :string           default("session"), not null
#  synced_at    :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string
#  project_id   :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  idx_on_project_id_metric_type_period_start_c4a679eb0b  (project_id,metric_type,period_start)
#  index_ai_productivity_metrics_on_external_id           (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_ai_productivity_metrics_on_metric_type           (metric_type)
#  index_ai_productivity_metrics_on_period_type           (period_type)
#  index_ai_productivity_metrics_on_project_id            (project_id)
#  index_ai_productivity_metrics_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :ai_productivity_metric do
    project
    user { project.user }
    metric_type { "time_saved" }
    period_type { "session" }
    period_start { 1.hour.ago }
    period_end { Time.current }
    metric_data { {} }

    trait :time_saved do
      metric_type { "time_saved" }
      metric_data do
        {
          ai_time_ms: rand(60_000..300_000),
          estimated_human_time_ms: rand(300_000..1_800_000),
          time_saved_minutes: rand(5..30),
          efficiency_ratio: rand(2.0..6.0).round(2)
        }
      end
    end

    trait :code_contribution do
      metric_type { "code_contribution" }
      metric_data do
        {
          lines_added: rand(10..500),
          lines_removed: rand(0..100),
          net_lines: rand(-50..400),
          files_changed: rand(1..20),
          commits: rand(1..10)
        }
      end
    end

    trait :task_velocity do
      metric_type { "task_velocity" }
      metric_data do
        {
          tasks_completed: rand(1..10),
          tasks_created: rand(1..15),
          completion_rate: rand(0.5..1.0).round(3)
        }
      end
    end

    trait :token_efficiency do
      metric_type { "token_efficiency" }
      metric_data do
        {
          total_tokens: rand(10_000..500_000),
          input_tokens: rand(5_000..250_000),
          output_tokens: rand(5_000..250_000),
          estimated_cost_usd: rand(0.01..5.0).round(4)
        }
      end
    end

    trait :daily do
      period_type { "daily" }
      period_start { 1.day.ago.beginning_of_day }
      period_end { 1.day.ago.end_of_day }
    end

    trait :weekly do
      period_type { "weekly" }
      period_start { 1.week.ago.beginning_of_week }
      period_end { 1.week.ago.end_of_week }
    end

    trait :synced do
      external_id { SecureRandom.uuid }
      synced_at { Time.current }
    end
  end
end
