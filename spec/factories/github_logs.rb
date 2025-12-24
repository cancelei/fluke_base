# == Schema Information
#
# Table name: github_logs
#
#  id                     :bigint           not null, primary key
#  changed_files          :jsonb            is an Array
#  commit_date            :datetime         not null
#  commit_message         :text
#  commit_sha             :string           not null
#  commit_url             :string
#  lines_added            :integer
#  lines_removed          :integer
#  unregistered_user_name :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  agreement_id           :bigint
#  project_id             :bigint           not null
#  user_id                :bigint
#
# Indexes
#
#  index_github_logs_on_agreement_id                (agreement_id)
#  index_github_logs_on_commit_date                 (commit_date)
#  index_github_logs_on_commit_sha                  (commit_sha) UNIQUE
#  index_github_logs_on_project_id                  (project_id)
#  index_github_logs_on_project_id_and_commit_date  (project_id,commit_date)
#  index_github_logs_on_user_id                     (user_id)
#  index_github_logs_on_user_id_and_commit_date     (user_id,commit_date)
#
# Foreign Keys
#
#  fk_rails_...  (agreement_id => agreements.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :github_log do
    association :project
    user { nil } # Allow nil for unregistered users
    sequence(:commit_sha) { |n| "deadbeef#{n.to_s(16).rjust(4, '0')}" }
    commit_message { 'Test commit message' }
    lines_added { 0 }
    lines_removed { 0 }
    commit_date { Time.current }
    commit_url { 'https://example.com/commit' }
    unregistered_user_name { nil }

    trait :with_user do
      association :user
    end

    trait :unregistered do
      user { nil }
      unregistered_user_name { 'unregistered_user' }
    end
  end
end
