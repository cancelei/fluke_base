# == Schema Information
#
# Table name: agreements
#
#  id                :bigint           not null, primary key
#  agreement_type    :string           not null
#  end_date          :date             not null
#  equity_percentage :decimal(5, 2)
#  hourly_rate       :decimal(10, 2)
#  milestone_ids     :integer          default([]), is an Array
#  payment_type      :string           not null
#  start_date        :date             not null
#  status            :string           not null
#  tasks             :text             not null
#  terms             :text
#  weekly_hours      :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_id        :bigint           not null
#
# Indexes
#
#  index_agreements_on_agreement_type             (agreement_type)
#  index_agreements_on_created_at                 (created_at)
#  index_agreements_on_payment_type               (payment_type)
#  index_agreements_on_project_id                 (project_id)
#  index_agreements_on_status                     (status)
#  index_agreements_on_status_and_agreement_type  (status,agreement_type)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
FactoryBot.define do
  factory :agreement do
    association :project
    agreement_type { Agreement::CO_FOUNDER }  # Default to co-founder to avoid milestone requirement
    payment_type { Agreement::EQUITY }
    status { Agreement::PENDING }
    start_date { 1.week.from_now }
    end_date { 4.weeks.from_now }
    tasks { "Complete project milestones" }
    weekly_hours { 20 }  # Default weekly hours for any agreement
    equity_percentage { 15.0 }
    milestone_ids { [] }
    terms { "Standard co-founder agreement terms" }

    # Use transient attributes for participants to avoid direct foreign key issues
    transient do
      initiator { nil }
      other_party { nil }
    end

    # Create agreement participants after building the agreement
    after(:create) do |agreement, evaluator|
      if evaluator.initiator && evaluator.other_party
        agreement.agreement_participants.create!(
          user: evaluator.initiator,
          project: agreement.project,
          user_role: "entrepreneur",
          is_initiator: true,
          accept_or_counter_turn_id: evaluator.other_party.id
        )

        # Determine role based on agreement type
        other_role = case agreement.agreement_type
        when Agreement::MENTORSHIP
                      "mentor"
        when Agreement::CO_FOUNDER
                      "co_founder"
        else
                      "collaborator"
        end

        agreement.agreement_participants.create!(
          user: evaluator.other_party,
          project: agreement.project,
          user_role: other_role,
          is_initiator: false,
          accept_or_counter_turn_id: evaluator.other_party.id
        )
      end
    end

    trait :with_participants do
      association :initiator, factory: :user
      association :other_party, factory: :user
    end

    trait :accepted do
      status { Agreement::ACCEPTED }
    end

    trait :completed do
      status { Agreement::COMPLETED }
    end

    trait :rejected do
      status { Agreement::REJECTED }
    end

    trait :mentorship do
      agreement_type { Agreement::MENTORSHIP }
      payment_type { Agreement::HOURLY }
      hourly_rate { 50.0 }
      weekly_hours { 10 }
      equity_percentage { nil }

      # Create milestones after project is created
      after(:build) do |agreement, evaluator|
        if agreement.project.present? && agreement.milestone_ids.empty?
          milestone = create(:milestone, project: agreement.project)
          agreement.milestone_ids = [milestone.id]
        end
      end
    end

    trait :co_founder do
      agreement_type { Agreement::CO_FOUNDER }
      payment_type { Agreement::EQUITY }
      equity_percentage { 15.0 }
      hourly_rate { nil }
      weekly_hours { 30 }  # Co-founders typically work more hours
      milestone_ids { [] }
    end
  end
end
