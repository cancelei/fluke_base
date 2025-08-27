class GithubBranch < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :github_branch_logs, dependent: :destroy
  has_many :github_logs, through: :github_branch_logs

  def latest_commit
    github_logs.order(commit_date: :desc).first
  end
end
