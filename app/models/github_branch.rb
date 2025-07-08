class GithubBranch < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :github_branch_logs
  has_many :github_logs, through: :github_branch_logs
end
