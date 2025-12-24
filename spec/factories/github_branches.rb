# == Schema Information
#
# Table name: github_branches
#
#  id          :bigint           not null, primary key
#  branch_name :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  idx_on_project_id_branch_name_user_id_fcdce7d2d8  (project_id,branch_name,user_id) UNIQUE
#  index_github_branches_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :github_branch do
    association :project
    association :user
    sequence(:branch_name) { |n| n.even? ? "main" : "feature/test-#{n}" }
  end
end
