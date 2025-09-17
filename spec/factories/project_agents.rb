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
