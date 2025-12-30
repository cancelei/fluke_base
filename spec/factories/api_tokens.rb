# frozen_string_literal: true

# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime
#  last_used_at :datetime
#  last_used_ip :string
#  name         :string           not null
#  prefix       :string(8)        not null
#  revoked_at   :datetime
#  scopes       :text             default([]), is an Array
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_prefix                  (prefix)
#  index_api_tokens_on_token_digest            (token_digest) UNIQUE
#  index_api_tokens_on_user_id                 (user_id)
#  index_api_tokens_on_user_id_and_revoked_at  (user_id,revoked_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :api_token do
    user
    name { "Test Token" }
    sequence(:token_digest) { |n| Digest::SHA256.hexdigest("fbk_test_token_#{n}") }
    prefix { "fbk_test" }
    scopes { ApiToken::DEFAULT_SCOPES }

    trait :with_memory_scopes do
      scopes { ApiToken::DEFAULT_SCOPES + %w[read:memories write:memories] }
    end

    trait :all_scopes do
      scopes { ["*"] }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :revoked do
      revoked_at { Time.current }
    end

    # Helper to create token with raw value for testing
    transient do
      raw_token { nil }
    end

    after(:build) do |api_token, evaluator|
      if evaluator.raw_token
        api_token.token_digest = Digest::SHA256.hexdigest(evaluator.raw_token)
        api_token.prefix = evaluator.raw_token[0, 8]
      end
    end
  end
end
