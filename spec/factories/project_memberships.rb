# == Schema Information
#
# Table name: project_memberships
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  invited_at    :datetime
#  role          :string           default("member"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  invited_by_id :bigint
#  project_id    :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_project_memberships_on_invited_by_id           (invited_by_id)
#  index_project_memberships_on_project_id              (project_id)
#  index_project_memberships_on_project_id_and_user_id  (project_id,user_id) UNIQUE
#  index_project_memberships_on_user_id                 (user_id)
#  index_project_memberships_on_user_id_and_role        (user_id,role)
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :project_membership do
    association :project
    association :user
    role { "member" }
    accepted_at { Time.current }

    trait :pending do
      accepted_at { nil }
    end

    trait :owner do
      role { "owner" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :guest do
      role { "guest" }
    end
  end
end
