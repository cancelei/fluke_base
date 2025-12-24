# == Schema Information
#
# Table name: projects
#
#  id                    :bigint           not null, primary key
#  category              :string
#  collaboration_type    :string
#  current_stage         :string
#  description           :text             not null
#  funding_status        :string
#  github_last_polled_at :datetime
#  name                  :string           not null
#  project_link          :string
#  public_fields         :string           default([]), not null, is an Array
#  repository_url        :string
#  slug                  :string
#  stage                 :string           not null
#  stealth_category      :string
#  stealth_description   :text
#  stealth_mode          :boolean          default(FALSE), not null
#  stealth_name          :string
#  target_market         :text
#  team_size             :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint           not null
#
# Indexes
#
#  index_projects_on_collaboration_type     (collaboration_type)
#  index_projects_on_created_at             (created_at)
#  index_projects_on_github_last_polled_at  (github_last_polled_at)
#  index_projects_on_slug                   (slug) UNIQUE
#  index_projects_on_stage                  (stage)
#  index_projects_on_stealth_mode           (stealth_mode)
#  index_projects_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :project do
    name { "FlukeBase Project" }
    description { "A sample project for testing milestone AI enhancement features" }
    stage { "prototype" }
    association :user

    trait :idea_stage do
      stage { "idea" }
    end

    trait :launched do
      stage { "launched" }
    end

    trait :scaling do
      stage { "scaling" }
    end

    trait :seeking_mentor do
      collaboration_type { "mentor" }
    end

    trait :seeking_cofounder do
      collaboration_type { "co_founder" }
    end
  end
end
