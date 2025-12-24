# == Schema Information
#
# Table name: milestones
#
#  id          :bigint           not null, primary key
#  description :text
#  due_date    :date             not null
#  slug        :string
#  status      :string           not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#
# Indexes
#
#  index_milestones_on_due_date                 (due_date)
#  index_milestones_on_project_id               (project_id)
#  index_milestones_on_project_id_and_due_date  (project_id,due_date)
#  index_milestones_on_project_id_and_slug      (project_id,slug) UNIQUE
#  index_milestones_on_project_id_and_status    (project_id,status)
#  index_milestones_on_status                   (status)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
FactoryBot.define do
  factory :milestone do
    title { "Build MVP Feature" }
    description { "Build a basic MVP with core features that demonstrates the primary value proposition" }
    due_date { 2.weeks.from_now }
    status { "pending" }
    association :project

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :overdue do
      due_date { 1.week.ago }
    end
  end
end
