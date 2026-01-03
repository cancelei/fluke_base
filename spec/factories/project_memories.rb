# frozen_string_literal: true

# == Schema Information
#
# Table name: project_memories
#
#  id          :bigint           not null, primary key
#  content     :text             not null
#  key         :string
#  memory_type :string           default("fact"), not null
#  rationale   :text
#  references  :jsonb
#  synced_at   :datetime
#  tags        :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  external_id :string
#  project_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_project_memories_on_external_id                 (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_project_memories_on_project_id                  (project_id)
#  index_project_memories_on_project_id_and_key          (project_id,key) UNIQUE WHERE (key IS NOT NULL)
#  index_project_memories_on_project_id_and_memory_type  (project_id,memory_type)
#  index_project_memories_on_user_id                     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :project_memory do
    project
    user { project.user }
    memory_type { "fact" }
    content { Faker::Lorem.sentence }
    tags { [] }
    references { {} }

    trait :convention do
      memory_type { "convention" }
      key { Faker::Lorem.word }
      rationale { Faker::Lorem.sentence }
    end

    trait :gotcha do
      memory_type { "gotcha" }
    end

    trait :decision do
      memory_type { "decision" }
    end

    trait :synced do
      external_id { SecureRandom.uuid }
      synced_at { Time.current }
    end

    trait :with_tags do
      tags { Faker::Lorem.words(number: 3) }
    end
  end
end
