# frozen_string_literal: true

# == Schema Information
#
# Table name: environment_variables
#
#  id               :bigint           not null, primary key
#  description      :text
#  environment      :string           default("development"), not null
#  example_value    :text
#  is_required      :boolean          default(FALSE), not null
#  is_secret        :boolean          default(FALSE), not null
#  key              :string           not null
#  validation_regex :string
#  value_ciphertext :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  created_by_id    :bigint           not null
#  project_id       :bigint           not null
#  updated_by_id    :bigint
#
# Indexes
#
#  idx_env_vars_project_env_key                               (project_id,environment,key) UNIQUE
#  index_environment_variables_on_created_by_id               (created_by_id)
#  index_environment_variables_on_project_id                  (project_id)
#  index_environment_variables_on_project_id_and_environment  (project_id,environment)
#  index_environment_variables_on_updated_by_id               (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (updated_by_id => users.id)
#
FactoryBot.define do
  factory :environment_variable do
    association :project
    association :created_by, factory: :user
    key { "TEST_#{SecureRandom.hex(4).upcase}" }
    environment { "development" }
    value_ciphertext { "test_value" }
    is_secret { false }
    is_required { false }

    trait :secret do
      is_secret { true }
      key { "SECRET_KEY_#{SecureRandom.hex(4).upcase}" }
    end

    trait :required do
      is_required { true }
    end

    trait :production do
      environment { "production" }
    end

    trait :staging do
      environment { "staging" }
    end
  end
end
