# frozen_string_literal: true

# == Schema Information
#
# Table name: agent_sessions
#
#  id                :bigint           not null, primary key
#  agent_type        :string           default("claude_code")
#  capabilities      :jsonb
#  client_version    :string
#  connected_at      :datetime
#  disconnected_at   :datetime
#  ip_address        :string
#  last_heartbeat_at :datetime
#  metadata          :jsonb
#  persona_name      :string
#  status            :string           default("active"), not null
#  tokens_used       :integer          default(0)
#  tools_executed    :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  agent_id          :string           not null
#  project_id        :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_agent_sessions_on_agent_id                 (agent_id)
#  index_agent_sessions_on_last_heartbeat_at        (last_heartbeat_at)
#  index_agent_sessions_on_persona_name             (persona_name)
#  index_agent_sessions_on_project_id               (project_id)
#  index_agent_sessions_on_project_id_and_agent_id  (project_id,agent_id) UNIQUE
#  index_agent_sessions_on_project_id_and_status    (project_id,status)
#  index_agent_sessions_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
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
