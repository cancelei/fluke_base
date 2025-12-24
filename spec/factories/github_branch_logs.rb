# == Schema Information
#
# Table name: github_branch_logs
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  github_branch_id :bigint           not null
#  github_log_id    :bigint           not null
#
# Indexes
#
#  index_github_branch_logs_on_github_branch_id_and_github_log_id  (github_branch_id,github_log_id) UNIQUE
#  index_github_branch_logs_on_github_log_id                       (github_log_id)
#
# Foreign Keys
#
#  fk_rails_...  (github_branch_id => github_branches.id) ON DELETE => cascade
#  fk_rails_...  (github_log_id => github_logs.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :github_branch_log do
    association :github_branch
    association :github_log
  end
end
