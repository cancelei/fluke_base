class GithubBranch < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :github_logs, foreign_key: "github_branches_id", dependent: :destroy
end
