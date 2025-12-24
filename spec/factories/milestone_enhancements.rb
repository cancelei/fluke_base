# == Schema Information
#
# Table name: milestone_enhancements
#
#  id                   :bigint           not null, primary key
#  context_data         :json
#  enhanced_description :text
#  enhancement_style    :string
#  original_description :text
#  processing_time_ms   :integer
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  milestone_id         :bigint           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_milestone_enhancements_on_milestone_id  (milestone_id)
#  index_milestone_enhancements_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (milestone_id => milestones.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :milestone_enhancement do
    association :milestone
    association :user
    original_description { "Build a basic MVP with core features" }
    enhanced_description { "Develop a Minimum Viable Product (MVP) that includes essential core features such as user authentication, basic dashboard functionality, and data management. The MVP should demonstrate the primary value proposition and be ready for initial user testing. Success criteria include: functional user registration/login, working dashboard with basic navigation, ability to create and manage data entries, and deployment to a staging environment for testing." }
    enhancement_style { "professional" }
    status { "completed" }
    processing_time_ms { 2500 }
    context_data do
      {
        processed_at: Time.current.iso8601,
        service_used: "MilestoneAiEnhancementService"
      }
    end

    trait :pending do
      status { "pending" }
      enhanced_description { "" }
      processing_time_ms { nil }
    end

    trait :processing do
      status { "processing" }
      enhanced_description { "" }
      processing_time_ms { nil }
    end

    trait :failed do
      status { "failed" }
      enhanced_description { "" }
      context_data do
        {
          error_message: "AI service temporarily unavailable",
          failed_at: Time.current.iso8601
        }
      end
    end

    trait :technical_style do
      enhancement_style { "technical" }
    end

    trait :creative_style do
      enhancement_style { "creative" }
    end

    trait :detailed_style do
      enhancement_style { "detailed" }
    end

    trait :concise_style do
      enhancement_style { "concise" }
    end
  end
end
