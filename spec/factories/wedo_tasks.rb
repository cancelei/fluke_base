# frozen_string_literal: true

# == Schema Information
#
# Table name: wedo_tasks
#
#  id               :bigint           not null, primary key
#  artifact_path    :string
#  blocked_by       :jsonb
#  completed_at     :datetime
#  dependency       :string           default("AGENT_CAPABLE"), not null
#  description      :text             not null
#  due_date         :date
#  priority         :string           default("normal"), not null
#  remote_url       :string
#  scope            :string           default("global"), not null
#  status           :string           default("pending"), not null
#  synthesis_report :text             default("")
#  tags             :jsonb
#  version          :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  assignee_id      :bigint
#  created_by_id    :bigint
#  external_id      :string
#  parent_task_id   :bigint
#  project_id       :bigint           not null
#  task_id          :string           not null
#  template_id      :string
#  updated_by_id    :bigint
#
# Indexes
#
#  index_wedo_tasks_on_assignee_id             (assignee_id)
#  index_wedo_tasks_on_created_at              (created_at)
#  index_wedo_tasks_on_created_by_id           (created_by_id)
#  index_wedo_tasks_on_external_id             (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_wedo_tasks_on_parent_task_id          (parent_task_id)
#  index_wedo_tasks_on_project_id              (project_id)
#  index_wedo_tasks_on_project_id_and_scope    (project_id,scope)
#  index_wedo_tasks_on_project_id_and_status   (project_id,status)
#  index_wedo_tasks_on_project_id_and_task_id  (project_id,task_id) UNIQUE
#  index_wedo_tasks_on_tags                    (tags) USING gin
#  index_wedo_tasks_on_updated_by_id           (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (parent_task_id => wedo_tasks.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (updated_by_id => users.id)
#
FactoryBot.define do
  factory :wedo_task do
    project
    sequence(:task_id) { |n| "TASK-#{n.to_s.rjust(3, '0')}" }
    description { Faker::Lorem.sentence }
    status { "pending" }
    dependency { "AGENT_CAPABLE" }
    scope { "global" }
    priority { "normal" }
    version { 0 }

    trait :pending do
      status { "pending" }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
    end

    trait :blocked do
      status { "blocked" }
    end

    trait :user_required do
      dependency { "USER_REQUIRED" }
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :urgent do
      priority { "urgent" }
    end

    trait :with_tags do
      tags { %w[feature api] }
    end

    trait :with_external_id do
      sequence(:external_id) { |n| "ext-#{SecureRandom.uuid[0, 8]}-#{n}" }
    end

    trait :with_parent do
      association :parent_task, factory: :wedo_task
    end

    trait :with_assignee do
      association :assignee, factory: :user
    end

    trait :with_creator do
      association :created_by, factory: :user
      association :updated_by, factory: :user
    end
  end
end
