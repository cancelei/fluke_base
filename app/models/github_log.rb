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
class GithubLog < ApplicationRecord
  belongs_to :project
  belongs_to :agreement, optional: true
  belongs_to :user, optional: true
  has_many :github_branch_logs
  has_many :github_branches, through: :github_branch_logs

  belongs_to :time_log, -> { where("agreement_id = ? AND commit_date BETWEEN started_at AND ended_at", agreement_id) }, optional: true

  validates :commit_sha, presence: true, uniqueness: true
  validates :lines_added, :lines_removed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :commit_date, presence: true

  # Scopes
  scope :recent, -> { order(commit_date: :desc) }
  scope :for_project, ->(project_id) { where(project_id:) }
  scope :for_user, ->(user_id) { where(user_id:) }
  scope :for_agreement, ->(agreement_id) { where(agreement_id:) }

  # Returns a summary of contributions by user for a project
  def self.contributions_summary(project_id)
    select("user_id, COUNT(*) as commit_count, SUM(lines_added) as total_added, SUM(lines_removed) as total_removed")
      .for_project(project_id)
      .group(:user_id)
      .includes(:user)
  end

  def time_log
    TimeLog.find_by(project_id:, started_at: ..commit_date, ended_at: commit_date..)
  end
end
