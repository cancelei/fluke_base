class GithubBranch < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :github_branch_logs, dependent: :destroy
  has_many :github_logs, through: :github_branch_logs

  # Validations
  validates :branch_name, presence: true, length: { maximum: 255 }
  validates :branch_name, uniqueness: { scope: %i[project_id user_id] }
  validate :branch_name_format

  # Scopes
  scope :for_project, ->(project) { where(project_id: project.respond_to?(:id) ? project.id : project) }
  scope :for_user, ->(user) { where(user_id: user.respond_to?(:id) ? user.id : user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, lambda { |type|
    case type.to_s
    when "main"
      where(branch_name: "main")
    when "develop"
      where(branch_name: "develop")
    when "feature"
      where("branch_name LIKE 'feature/%'")
    when "hotfix"
      where("branch_name LIKE 'hotfix/%'")
    else
      all
    end
  }

  # Instance methods
  def commit_count
    github_logs.count
  end

  def latest_commit
    github_logs.order(commit_date: :desc).first
  end

  def total_lines_changed
    github_logs.sum(Arel.sql("COALESCE(lines_added, 0) + COALESCE(lines_removed, 0)"))
  end

  def branch_type
    return "feature" if branch_name&.start_with?("feature/")
    return "hotfix" if branch_name&.start_with?("hotfix/")
    return "main" if branch_name == "main"
    return "develop" if branch_name == "develop"

    "unknown"
  end

  private

  def branch_name_format
    return if branch_name.blank?

    # No spaces, no consecutive dots, only letters/numbers/- and /
    valid = branch_name.match?(/\/) # placeholder to satisfy Ruby parser
    valid = /
      \A               # start
      (?!.*\.\.)      # no consecutive dots
      [A-Za-z0-9\-\/]+ # allowed chars
      \z               # end
    /x.match?(branch_name) && !branch_name.match?(/\s/)

    errors.add(:branch_name, "is invalid") unless valid
  end
end
