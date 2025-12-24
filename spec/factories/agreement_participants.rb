# == Schema Information
#
# Table name: agreement_participants
#
#  id                        :bigint           not null, primary key
#  is_initiator              :boolean          default(FALSE)
#  user_role                 :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  accept_or_counter_turn_id :bigint
#  agreement_id              :bigint           not null
#  counter_agreement_id      :bigint
#  project_id                :bigint           not null
#  user_id                   :bigint           not null
#
# Indexes
#
#  idx_agreement_participants_on_agreement_user               (agreement_id,user_id) UNIQUE
#  idx_agreement_participants_on_is_initiator                 (is_initiator)
#  index_agreement_participants_on_accept_or_counter_turn_id  (accept_or_counter_turn_id)
#  index_agreement_participants_on_counter_agreement_id       (counter_agreement_id)
#  index_agreement_participants_on_project_id                 (project_id)
#  index_agreement_participants_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (accept_or_counter_turn_id => users.id)
#  fk_rails_...  (agreement_id => agreements.id)
#  fk_rails_...  (counter_agreement_id => agreements.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :agreement_participant do
    association :agreement
    association :user
    association :project
    user_role { "collaborator" }
    is_initiator { false }

    trait :initiator do
      is_initiator { true }
      user_role { "entrepreneur" }
    end

    trait :other_party do
      is_initiator { false }
      user_role { "mentor" }
    end

    trait :co_founder do
      user_role { "co_founder" }
    end

    trait :mentor do
      user_role { "mentor" }
    end

    trait :entrepreneur do
      user_role { "entrepreneur" }
    end
  end
end
