# frozen_string_literal: true

FactoryBot.define do
  factory :agent_session do
    project
    user { project.user }
    sequence(:agent_id) { |n| "session-#{SecureRandom.hex(4)}-#{n}" }
    agent_type { "claude_code" }
    status { "active" }
    connected_at { Time.current }
    last_heartbeat_at { Time.current }
    capabilities { %w[memory wedo] }
    client_version { "1.0.0" }

    trait :with_persona do
      persona_name { %w[ZION KORE ATLAS NOVA].sample }
    end

    trait :idle do
      status { "idle" }
      last_heartbeat_at { 3.minutes.ago }
    end

    trait :disconnected do
      status { "disconnected" }
      disconnected_at { Time.current }
    end

    trait :stale do
      last_heartbeat_at { 5.minutes.ago }
    end

    trait :with_tokens do
      tokens_used { rand(1000..50000) }
      tools_executed { rand(10..100) }
    end
  end
end
