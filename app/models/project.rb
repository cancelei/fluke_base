require "ostruct"

class Project < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :agreements, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_many :mentorships, -> { where(agreement_type: "Mentorship") }, class_name: "Agreement", foreign_key: "project_id"
  has_many :mentors, through: :mentorships, source: :other_party

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :stage, presence: true
  validates :collaboration_type, inclusion: { in: [ "mentor", "co_founder", "both", nil ] }
  validates :repository_url, format: {
    with: /(^$|^https?:\/\/github\.com\/[^\/]+\/[^\/]+$|^[^\/\s]+\/[^\/\s]+$)/,
    message: "must be a valid GitHub repository URL or in the format username/repository"
  }, allow_blank: true

  # Default values and lifecycle hooks
  before_save :set_defaults

  # Project stages
  IDEA = "idea"
  PROTOTYPE = "prototype"
  LAUNCHED = "launched"
  SCALING = "scaling"

  # Collaboration types
  SEEKING_MENTOR = "mentor"
  SEEKING_COFOUNDER = "co_founder"
  SEEKING_BOTH = "both"

  # Public field options
  PUBLIC_FIELD_OPTIONS = %w[
    name description stage category current_stage
    target_market funding_status team_size collaboration_type
  ]

  # Associations
  has_many :github_logs, dependent: :destroy
  has_many :github_branches, dependent: :destroy

  # GitHub integration methods

  # Fetches and stores commits from GitHub
  # @param access_token [String] GitHub access token
  # @param branch [String] Optional branch name to fetch commits from
  # @return [Integer] Number of new commits stored


  # Get available branches from GitHub logs
  # @return [Array<String>] List of branch names
  def available_branches
    github_branches.pluck(:id, :branch_name).compact.sort
  end

  # Get summary of GitHub contributions by user
  # @param branch [String] Optional branch name to filter by
  # @return [Array<Hash>] Array of contribution hashes with user details and stats
  def github_contributions(branch: nil, agreement_only: false, agreement_user_ids: nil, user_name: nil)
    return [] unless github_logs.exists?

    # Apply agreement filter if needed
    if agreement_only
      registered_query = github_logs.joins(:user, :github_branch_logs)
                                 .where(users: { id: agreement_user_ids })
      unregistered_query = github_logs.none  # Exclude unregistered users when filtering by agreement
    else
      registered_query = github_logs.joins(:user, :github_branch_logs).where.not(users: { id: nil })
      unregistered_query = github_logs.joins(:github_branch_logs).where(user_id: nil).where.not(unregistered_user_name: [ nil, "" ])
    end

    # Apply user_name filter if needed
    if user_name
      registered_query = registered_query.where(unregistered_user_name: user_name)
      unregistered_query = unregistered_query.where(unregistered_user_name: user_name)
    end

    # Filter by branch if specified
    if branch.present? && branch.to_i != 0
      registered_query = registered_query.where(github_branch_logs: { github_branch_id: branch })
      unregistered_query = unregistered_query.where(github_branch_logs: { github_branch_id: branch })
    end

    # Get registered users' contributions
    registered_contributions = registered_query
      .group("users.id", "users.first_name", "users.last_name", "users.email", "users.avatar", "users.github_username")
      .select(
        "users.id as user_id",
        "users.first_name",
        "users.last_name",
        "users.email",
        "users.avatar",
        "users.github_username",
        "NULL as unregistered_user_name",
        "COUNT(github_logs.id) as commit_count",
        "SUM(github_logs.lines_added) as total_added",
        "SUM(github_logs.lines_removed) as total_removed",
        "MIN(github_logs.commit_date) as first_commit_date",
        "MAX(github_logs.commit_date) as last_commit_date"
      )

    # Get unregistered users' contributions
    unregistered_contributions = unregistered_query
      .group("github_logs.unregistered_user_name")
      .select(
        "NULL as user_id",
        "NULL as first_name",
        "NULL as last_name",
        "NULL as email",
        "NULL as avatar",
        "NULL as github_username",
        "github_logs.unregistered_user_name",
        "COUNT(github_logs.id) as commit_count",
        "SUM(github_logs.lines_added) as total_added",
        "SUM(github_logs.lines_removed) as total_removed",
        "MIN(github_logs.commit_date) as first_commit_date",
        "MAX(github_logs.commit_date) as last_commit_date"
      )

    # Combine and sort all contributions by commit count
    all_contributions = (registered_contributions.to_a + unregistered_contributions.to_a)
      .sort_by { |c| -c.commit_count.to_i }

    # Convert to array of hashes with proper types
    all_contributions.map do |c|
      user = if c.user_id.present?
        User.find(c.user_id)
      else
        # Create a simple object that responds to the methods the view expects
        unregistered_user = OpenStruct.new(
          id: nil,
          name: c.unregistered_user_name,
          github_username: c.unregistered_user_name,
          unregistered: true
        )

        # Define methods needed by the view
        def unregistered_user.avatar_url
          nil
        end

        def unregistered_user.full_name
          name
        end

        def unregistered_user.owner?(_project)
          false
        end

        unregistered_user
      end

      {
        user: user,
        commit_count: c.commit_count.to_i,
        total_added: c.total_added.to_i,
        total_removed: c.total_removed.to_i,
        net_changes: c.total_added.to_i - c.total_removed.to_i,
        first_commit_date: c.first_commit_date,
        last_commit_date: c.last_commit_date
      }
    end
  end

  # Check if a user can view GitHub logs for this project
  # @param user [User] The user to check
  # @return [Boolean] True if user can view logs
  def can_view_github_logs?(user)
    return false unless user

    # Project owner can always view
    return true if user_id == user.id

    # Check for accepted agreements
    agreements.accepted.exists?(other_party_id: user.id)
  end

  # Get recent GitHub logs
  # @param limit [Integer] Number of logs to return
  # @return [ActiveRecord::Relation] Recent GitHub logs
  def recent_github_logs(limit = 20)
    github_logs.includes(:user).order(commit_date: :desc).limit(limit)
  end

  def contributions_summary
    github_logs.select("user_id, COUNT(*) as commit_count, SUM(lines_added) as total_added, SUM(lines_removed) as total_removed")
              .group(:user_id)
              .includes(:user)
  end

  def can_view_github_logs?(user)
    return false if user.nil? || repository_url.blank?
    user_id == user.id ||
    agreements.active.exists?([ "(initiator_id = :user_id OR other_party_id = :user_id)", { user_id: user.id } ])
  end

  # Scopes
  scope :ideas, -> { where(stage: IDEA) }
  scope :prototypes, -> { where(stage: PROTOTYPE) }
  scope :launched, -> { where(stage: LAUNCHED) }
  scope :scaling, -> { where(stage: SCALING) }

  scope :seeking_mentor, -> { where("collaboration_type = ? OR collaboration_type = ?", SEEKING_MENTOR, SEEKING_BOTH) }
  scope :seeking_cofounder, -> { where("collaboration_type = ? OR collaboration_type = ?", SEEKING_COFOUNDER, SEEKING_BOTH) }

  # Helper methods for checking collaboration type
  def seeking_mentor?
    collaboration_type == SEEKING_MENTOR || collaboration_type == SEEKING_BOTH
  end

  def seeking_cofounder?
    collaboration_type == SEEKING_COFOUNDER || collaboration_type == SEEKING_BOTH
  end

  # Public field methods - data access only, presentation logic moved to helper
  def field_public?(field_name)
    return false unless public_fields.is_a?(Array)
    public_fields.include?(field_name.to_s)
  end

  def visible_to_user?(field_name, user)
    return true if user && (user_id == user.id)
    return true if field_public?(field_name)
    return true if user && agreements.exists?(other_party_id: user.id)
    false
  end

  # Methods
  def progress_percentage
    return 0 if milestones.empty?

    completed = milestones.where(status: "completed").count
    (completed.to_f / milestones.count * 100).round
  end

  # Methods to check current stage
  def idea?
    stage == IDEA
  end

  def prototype?
    stage == PROTOTYPE
  end

  def launched?
    stage == LAUNCHED
  end

  def scaling?
    stage == SCALING
  end

  # Check if project is connected to GitHub
  # @return [Boolean] True if the project has a repository URL set
  def github_connected?
    repository_url.present?
  end

  private

  def set_defaults
    self.stage ||= IDEA
    self.current_stage ||= stage.humanize if stage.present?
    self.collaboration_type ||= SEEKING_MENTOR
    self.public_fields ||= []
  end
end
