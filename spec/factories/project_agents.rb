# == Schema Information
#
# Table name: project_agents
#
#  id         :bigint           not null, primary key
#  model      :string
#  provider   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :bigint           not null
#
# Indexes
#
#  index_project_agents_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
FactoryBot.define do
  factory :project_agent do
    association :project
    provider { "openai" }
    model { "gpt-4" }

    trait :anthropic do
      provider { "anthropic" }
      model { "claude-3-sonnet" }
    end

    trait :with_gpt_turbo do
      model { "gpt-4-turbo" }
    end
  end
end
