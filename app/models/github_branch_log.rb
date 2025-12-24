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
class GithubBranchLog < ApplicationRecord
  belongs_to :github_branch
  belongs_to :github_log

  # Validations
  validates :github_branch, presence: true
  validates :github_log, presence: true
  validates :github_log_id, uniqueness: { scope: :github_branch_id }

  # Scopes
  scope :for_branch, ->(branch) do
    branch_id = branch.respond_to?(:id) ? branch.id : branch
    where(github_branch_id: branch_id)
  end

  scope :recent, -> { joins(:github_log).order("github_logs.commit_date DESC") }

  # Instance methods
  def commit_info
    return {} unless github_log

    {
      sha: github_log.commit_sha,
      message: github_log.commit_message,
      date: github_log.commit_date,
      author: github_log.user&.full_name
    }
  end

  def lines_changed
    (github_log&.lines_added.to_i) + (github_log&.lines_removed.to_i)
  end

  def branch_name
    github_branch&.branch_name
  end
end
