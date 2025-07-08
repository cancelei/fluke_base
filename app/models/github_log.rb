class GithubLog < ApplicationRecord
  belongs_to :project
  belongs_to :agreement, optional: true
  belongs_to :user
  has_many :github_branch_logs
  has_many :github_branches, through: :github_branch_logs

  belongs_to :time_log, -> { where("agreement_id = ? AND commit_date BETWEEN started_at AND ended_at", agreement_id) }, optional: true

  validates :commit_sha, presence: true, uniqueness: true
  validates :lines_added, :lines_removed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :commit_date, presence: true

  # Scopes
  scope :recent, -> { order(commit_date: :desc) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_agreement, ->(agreement_id) { where(agreement_id: agreement_id) }

  # Returns a summary of contributions by user for a project
  def self.contributions_summary(project_id)
    select("user_id, COUNT(*) as commit_count, SUM(lines_added) as total_added, SUM(lines_removed) as total_removed")
      .for_project(project_id)
      .group(:user_id)
      .includes(:user)
  end

  def time_log
    TimeLog.find_by(agreement_id: agreement_id, started_at: ..commit_date, ended_at: commit_date..)
  end
end
