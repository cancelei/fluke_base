# frozen_string_literal: true

class Project < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :agreements, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_one :project_agent, dependent: :destroy
  has_many :mentorships, -> { where(agreement_type: "Mentorship") }, class_name: "Agreement", foreign_key: "project_id"
  has_many :mentors, through: :mentorships, source: :other_party
  has_many :time_logs

  # Membership associations for tiered access control
  has_many :project_memberships, dependent: :destroy
  has_many :team_members, through: :project_memberships, source: :user

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :stage, presence: true
  validates :collaboration_type, inclusion: { in: ["mentor", "co_founder", "both", nil] }
  validates :repository_url, format: {
    with: /\A([a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+)?\z/,
    message: "must be a valid GitHub repository (e.g., username/repository)"
  }, allow_blank: true

  # Default values and lifecycle hooks
  before_validation :normalize_repository_url
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

  # Field privacy controls
  DEFAULT_PUBLIC_FIELDS = %w[name description stage collaboration_type category funding_status team_size].freeze
  PUBLIC_FIELD_OPTIONS = %w[
    name description stage category current_stage
    target_market funding_status team_size collaboration_type
    project_link
  ].freeze

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
    github_service.available_branches
  end

  # Get summary of GitHub contributions by user
  # @param branch [String] Optional branch name to filter by
  # @param agreement_only [Boolean] Filter by agreement participants only
  # @param agreement_user_ids [Array<Integer>] User IDs from agreements
  # @param user_name [String] Filter by specific user name
  # @return [Array<Hash>] Array of contribution hashes with user details and stats
  def github_contributions(branch: nil, agreement_only: false, agreement_user_ids: nil, user_name: nil)
    Github::ContributionsSummary.new(
      project: self,
      branch:,
      agreement_only:,
      agreement_user_ids:,
      user_name:
    ).call
  end

  # Check if a user can view GitHub logs for this project
  # @param user [User] The user to check
  # @return [Boolean] True if user can view logs
  def can_view_github_logs?(user)
    github_service.can_view_logs?(user)
  end

  # Get recent GitHub logs
  # @param limit [Integer] Number of logs to return
  # @return [ActiveRecord::Relation] Recent GitHub logs
  def recent_github_logs(limit = 20)
    github_logs.includes(:user, github_branch_logs: :github_branch)
               .order(commit_date: :desc)
               .limit(limit)
  end

  # GitHub Activity Helper Methods for Dashboard/Cards

  # Returns the most recent commit date for this project
  # @return [DateTime, nil] The most recent commit date or nil if no commits
  def last_commit_date
    github_logs.maximum(:commit_date)
  end

  # Returns the activity level based on last commit date
  # @return [Symbol] :active (7 days), :moderate (30 days), or :stale (older/no commits)
  def activity_level
    return :none unless github_connected?
    github_statistics_calculator.activity_level
  end

  # Returns the count of commits in the last N days
  # @param days [Integer] Number of days to look back (default: 7)
  # @return [Integer] Count of commits
  def commits_since(days: 7)
    github_statistics_calculator.commits_since(days:)
  end

  # Returns a hash with GitHub activity summary stats
  # @return [Hash] Activity stats including commit count, lines changed, last commit, etc.
  def github_activity_stats
    return {} unless github_connected?
    github_statistics_calculator.to_h
  end

  def contributions_summary
    github_service.contributions_summary_basic
  end

  def can_access_repository?(user)
    github_service.can_access_repository?(user)
  end

  # Scopes
  scope :ideas, -> { where(stage: IDEA) }
  scope :prototypes, -> { where(stage: PROTOTYPE) }
  scope :launched, -> { where(stage: LAUNCHED) }
  scope :scaling, -> { where(stage: SCALING) }

  scope :seeking_mentor, -> { where("collaboration_type = ? OR collaboration_type = ?", SEEKING_MENTOR, SEEKING_BOTH) }
  scope :seeking_cofounder, -> { where("collaboration_type = ? OR collaboration_type = ?", SEEKING_COFOUNDER, SEEKING_BOTH) }

  # Stealth mode scopes
  scope :publicly_visible, -> { where(stealth_mode: false) }
  scope :stealth_projects, -> { where(stealth_mode: true) }

  # Helper methods for checking collaboration type
  def seeking_mentor? = collaboration_type == SEEKING_MENTOR || collaboration_type == SEEKING_BOTH
  def seeking_cofounder? = collaboration_type == SEEKING_COFOUNDER || collaboration_type == SEEKING_BOTH

  # Public field methods - delegated to visibility service
  def field_public?(field_name) = visibility_service.field_public?(field_name)
  def visible_to_user?(field_name, user) = visibility_service.field_visible_to_user?(field_name, user)
  def get_field_value(field_name, user) = visibility_service.get_field_value(field_name, user)

  # Methods
  def progress_percentage
    return 0 if milestones_count == 0

    completed_count = milestones.completed.count
    (completed_count.to_f / milestones_count * 100).round
  end

  def milestones_count = @milestones_count ||= milestones.count

  # Methods to check current stage
  def idea? = stage == IDEA
  def prototype? = stage == PROTOTYPE
  def launched? = stage == LAUNCHED
  def scaling? = stage == SCALING

  # Stealth mode methods
  def stealth? = stealth_mode?

  def publicly_discoverable? = !stealth_mode?
  def exit_stealth_mode! = update!(stealth_mode: false)
  def stealth_display_name = stealth_name.presence || "Stealth Project ##{id}"
  def stealth_display_description = stealth_description.presence || "Early-stage venture in development. Details available after connection."

  # Check if project is connected to GitHub
  # @return [Boolean] True if the project has a repository URL set
  def github_connected? = github_service.connected?

  # ============================================================================
  # Membership-based Access Control Methods
  # ============================================================================

  # Find membership for a specific user
  # @param user [User] The user to find membership for
  # @return [ProjectMembership, nil] The membership record or nil
  def membership_for(user)
    return nil unless user
    project_memberships.find_by(user_id: user.id)
  end

  # Get the role for a specific user
  # @param user [User] The user to get role for
  # @return [String, nil] The role name or nil if no membership
  def role_for(user) = membership_for(user)&.role

  # Check if user is the project owner (original owner or owner role)
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_owner?(user)
    return false unless user
    user_id == user.id || membership_for(user)&.owner?
  end

  # Check if user has admin or higher access
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_admin?(user)
    return false unless user
    user_is_owner?(user) || membership_for(user)&.admin?
  end

  # Check if user has member or higher access
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_member?(user)
    return false unless user
    membership = membership_for(user)
    membership&.member? || has_active_agreement_with?(user)
  end

  # Check if user is a guest
  # @param user [User] The user to check
  # @return [Boolean]
  def user_is_guest?(user)
    return false unless user
    membership_for(user)&.guest?
  end

  # Check if user has any access to the project
  # @param user [User] The user to check
  # @return [Boolean]
  def user_has_access?(user)
    return false unless user
    membership_for(user).present? || has_active_agreement_with?(user)
  end

  # Check if user has an active agreement with this project
  # @param user [User] The user to check
  # @return [Boolean]
  def has_active_agreement_with?(user)
    return false unless user
    agreements.joins(:agreement_participants)
              .where(agreement_participants: { user_id: user.id })
              .where(status: %w[Accepted Completed])
              .exists?
  end

  # Get fields visible to a specific role
  # @param role [String] The role to check
  # @return [Array<String>] List of visible field names
  def fields_visible_to_role(role)
    case role.to_s
    when "owner"
      # Owners see everything
      PUBLIC_FIELD_OPTIONS + %w[repository_url stealth_name stealth_description stealth_category milestones agreements time_logs github_logs]
    when "admin"
      # Admins see most fields plus internal data
      PUBLIC_FIELD_OPTIONS + %w[milestones agreements time_logs]
    when "member"
      # Members see public fields plus shared project info
      (public_fields || DEFAULT_PUBLIC_FIELDS)
    when "guest"
      # Guests see only explicitly public fields, respecting stealth mode
      return [] if stealth?
      (public_fields || []).select { |f| f.in?(%w[name category stage]) }
    else
      []
    end
  end

  # Determine effective role for a user (considers agreements too)
  # @param user [User] The user to check
  # @return [String, nil] The effective role
  def effective_role_for(user)
    return nil unless user

    # Check if user is the original owner
    return "owner" if user_id == user.id

    # Check explicit membership
    membership = membership_for(user)
    return membership.role if membership

    # Check if user has access via agreements
    return "member" if has_active_agreement_with?(user)

    # Check if project is publicly discoverable
    return "guest" if publicly_discoverable?

    nil
  end

  private

  def github_service
    @github_service ||= ProjectGithubService.new(self)
  end

  def github_statistics_calculator
    @github_statistics_calculator ||= Github::StatisticsCalculator.new(project: self)
  end

  def visibility_service
    @visibility_service ||= ProjectVisibilityService.new(self)
  end

  def set_defaults
    self.stage ||= IDEA
    self.current_stage ||= stage.humanize if stage.present?
    self.collaboration_type ||= SEEKING_MENTOR

    # Handle stealth mode defaults
    if stealth_mode?
      # Stealth projects default to completely private
      self.public_fields = [] if public_fields.blank?
      # Set stealth-specific defaults if not already set
      set_stealth_defaults
    else
      # Make essential fields public by default for better project discovery
      self.public_fields = DEFAULT_PUBLIC_FIELDS if public_fields.blank?
    end
  end

  def set_stealth_defaults
    self.stealth_name ||= generate_stealth_name if stealth_name.blank?
    self.stealth_description ||= "Early-stage venture in development. Details available after connection." if stealth_description.blank?
    self.stealth_category ||= "Technology" if stealth_category.blank?
  end

  def generate_stealth_name
    "Stealth Startup #{SecureRandom.hex(2).upcase}"
  end

  def normalize_repository_url
    return if repository_url.blank?

    url = repository_url.to_s.strip

    # Remove query parameters and fragments
    url = url.split("?").first.to_s
    url = url.split("#").first.to_s

    if url.match?(%r{github\.com/}i)
      # Extract path after github.com/
      path = url.gsub(%r{^https?://(www\.)?github\.com/}i, "")
      # Remove .git suffix, trailing slashes, and extra paths (tree/main, issues, etc.)
      path = path.gsub(/\.git$/i, "").gsub(%r{/+$}, "")
      # Take only first two segments (owner/repo)
      segments = path.split("/").first(2)
      self.repository_url = segments.length == 2 ? segments.join("/") : nil
    else
      # Already in owner/repo format - just clean it
      self.repository_url = url.gsub(/\.git$/i, "").gsub(%r{/+$}, "")
    end
  end
end
