# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                    :bigint           not null, primary key
#  category              :string
#  collaboration_type    :string
#  current_stage         :string
#  description           :text             not null
#  funding_status        :string
#  github_last_polled_at :datetime
#  name                  :string           not null
#  project_link          :string
#  public_fields         :string           default([]), not null, is an Array
#  repository_url        :string
#  slug                  :string
#  stage                 :string           not null
#  stealth_category      :string
#  stealth_description   :text
#  stealth_mode          :boolean          default(FALSE), not null
#  stealth_name          :string
#  target_market         :text
#  team_size             :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint           not null
#
# Indexes
#
#  index_projects_on_collaboration_type     (collaboration_type)
#  index_projects_on_created_at             (created_at)
#  index_projects_on_github_last_polled_at  (github_last_polled_at)
#  index_projects_on_slug                   (slug) UNIQUE
#  index_projects_on_stage                  (stage)
#  index_projects_on_stealth_mode           (stealth_mode)
#  index_projects_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

# Project model representing a software project on FlukeBase.
#
# Projects are the central entity around which agreements, milestones,
# time tracking, and GitHub integration revolve. Each project has one owner
# but can have multiple collaborators via agreements.
#
# @example Creating a project with GitHub repository
#   project = user.projects.create!(
#     name: 'My App',
#     description: 'A Rails application',
#     stage: 'development',
#     repository_url: 'https://github.com/user/my-app'
#   )
#
# @example Stealth mode (hide details from public)
#   project.update!(stealth_mode: true, stealth_name: 'Project X')
#
# == Associations
# - +user+ - Owner of this project
# - +milestones+ - Deliverable milestones for tracking progress
# - +agreements+ - Collaboration agreements with other users
# - +environment_variables+ - Stored env vars for sync
# - +project_memories+ - Stored knowledge (facts, conventions, gotchas)
# - +github_logs+ - Synced GitHub activity
#
# == Key Features
# - Stealth mode: Hide real project details behind aliases
# - GitHub integration: Sync commits, PRs, and activity
# - Environment sync: Store and sync .env variables securely
# - Memory storage: Persist project knowledge for AI agents
#
# == Scopes
# - +published+ - Non-stealth projects visible to public
# - +by_stage+ - Filter by development stage
#
# @see Milestone
# @see Agreement
# @see EnvironmentVariable
class Project < ApplicationRecord
  extend FriendlyId
  include UrlNormalizable
  include AccessControl

  friendly_id :name, use: [:slugged, :finders]

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

  # Environment variables for flukebase_connect
  has_many :environment_variables, dependent: :destroy
  has_many :environment_configs, dependent: :destroy

  # MCP plugin configuration
  has_one :mcp_configuration, class_name: "ProjectMcpConfiguration", dependent: :destroy

  # Project memories for flukebase_connect sync
  has_many :project_memories, dependent: :destroy

  # AI Productivity metrics
  has_many :ai_productivity_metrics, dependent: :destroy
  has_one :ai_productivity_stat

  # AI Conversation logs from flukebase_connect
  has_many :ai_conversation_logs, dependent: :destroy

  # Auto-generated gotcha suggestions from pattern analysis
  has_many :suggested_gotchas, dependent: :destroy

  # Webhook subscriptions for real-time notifications
  has_many :webhook_subscriptions, dependent: :destroy

  # WeDo tasks for team board
  has_many :wedo_tasks, dependent: :destroy

  # Agent sessions from flukebase_connect
  has_many :agent_sessions, dependent: :destroy

  # Container pool for smart delegation
  has_one :container_pool, dependent: :destroy
  has_many :delegation_requests, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :stage, presence: true
  validates :collaboration_type, inclusion: { in: ["mentor", "co_founder", "both", nil] }
  validates :repository_url, format: {
    with: /\A([a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+)?\z/,
    message: "must be a valid GitHub repository (e.g., username/repository)"
  }, allow_blank: true
  validate :project_link_is_valid_url

  # Default values and lifecycle hooks
  before_validation :normalize_repository_url
  before_validation :normalize_project_link
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
  # Environment Variable Helper Methods (for flukebase_connect)
  # ============================================================================

  # Get environment variables for a specific environment
  # @param environment [String] The environment (development, staging, production)
  # @return [ActiveRecord::Relation] Environment variables for that environment
  def env_vars_for(environment = "development")
    environment_variables.for_environment(environment)
  end

  # Check if project has environment variables configured
  # @param environment [String] The environment to check
  # @return [Boolean] True if environment has variables
  def has_environment?(environment = "development")
    environment_variables.for_environment(environment).any?
  end

  # Get or create environment config for tracking sync
  # @param environment [String] The environment
  # @return [EnvironmentConfig] The config record
  def environment_config_for(environment = "development")
    environment_configs.find_or_create_by!(environment:)
  end

  # Ransack configuration for search/filter functionality
  def self.ransackable_attributes(auth_object = nil)
    %w[name description category collaboration_type stage stealth_mode created_at updated_at user_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user agreements milestones]
  end

  # FriendlyId: regenerate slug when name changes
  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
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

  def normalize_project_link
    self.project_link = normalize_url_for_storage(project_link)
  end

  def project_link_is_valid_url
    return if project_link.blank?

    # Build a full URL for validation
    test_url = "https://#{project_link}"

    begin
      uri = URI.parse(test_url)
      # Must have a valid host with at least one dot (e.g., example.com)
      unless uri.host.present? && uri.host.include?(".")
        errors.add(:project_link, "must be a valid website URL (e.g., example.com)")
      end
    rescue URI::InvalidURIError
      errors.add(:project_link, "must be a valid website URL (e.g., example.com)")
    end
  end
end
