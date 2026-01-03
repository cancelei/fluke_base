# frozen_string_literal: true

module Github
  # Manages fair distribution of GitHub API quota across multiple projects
  #
  # When a user has multiple projects sharing the same token, this service
  # ensures fair distribution of the remaining rate limit quota.
  #
  # Features:
  # - Tracks projects per token
  # - Calculates fair quota allocation per project
  # - Provides graceful degradation as limit approaches
  # - Adjusts polling frequency based on remaining quota
  #
  # Usage:
  #   manager = Github::TokenQuotaManager.new(token)
  #   quota = manager.quota_for_project(project_id)
  #   # => { allowed_calls: 100, poll_interval_multiplier: 1.0 }
  #
  #   if manager.can_poll_project?(project_id, cost: 5)
  #     # Proceed with polling
  #   end
  #
  class TokenQuotaManager
    # Minimum calls to reserve per project
    MIN_CALLS_PER_PROJECT = 10

    # Base polling interval multiplier (1.0 = normal)
    BASE_POLL_MULTIPLIER = 1.0

    # Maximum polling interval multiplier when rate limited
    MAX_POLL_MULTIPLIER = 10.0

    # Cache TTL for project tracking
    PROJECT_CACHE_TTL = 10.minutes

    attr_reader :token, :rate_limit_tracker

    def initialize(token)
      @token = token
      @rate_limit_tracker = RateLimitTracker.new(token)
    end

    # Get quota allocation for a specific project
    # @param project_id [Integer] Project ID
    # @return [Hash] { allowed_calls:, poll_interval_multiplier:, can_poll: }
    def quota_for_project(project_id)
      status = rate_limit_tracker.current_status
      remaining = status[:remaining] || default_remaining
      limit = status[:limit] || default_limit

      projects = projects_using_token
      project_count = [projects.count, 1].max

      # Calculate fair share
      fair_share = (remaining / project_count.to_f).floor

      # Calculate poll multiplier based on consumption
      consumption = rate_limit_tracker.consumption_percent
      multiplier = calculate_poll_multiplier(consumption)

      {
        allowed_calls: [fair_share, MIN_CALLS_PER_PROJECT].max,
        poll_interval_multiplier: multiplier,
        can_poll: fair_share >= MIN_CALLS_PER_PROJECT,
        remaining: remaining,
        limit: limit,
        consumption_percent: consumption,
        projects_sharing: project_count
      }
    end

    # Check if a project can poll with the given cost
    # @param project_id [Integer] Project ID
    # @param cost [Integer] Estimated API calls
    # @return [Boolean]
    def can_poll_project?(project_id, cost: 1)
      quota = quota_for_project(project_id)
      quota[:can_poll] && quota[:allowed_calls] >= cost
    end

    # Register a project as using this token
    # @param project_id [Integer] Project ID
    def register_project(project_id)
      projects = projects_using_token
      projects << project_id unless projects.include?(project_id)
      save_projects(projects)
    end

    # Unregister a project from this token
    # @param project_id [Integer] Project ID
    def unregister_project(project_id)
      projects = projects_using_token
      projects.delete(project_id)
      save_projects(projects)
    end

    # Get all projects using this token
    # @return [Array<Integer>] Project IDs
    def projects_using_token
      Rails.cache.read(projects_cache_key) || []
    end

    # Get recommended polling interval based on current rate limit status
    # @return [Integer] Seconds to wait between polls
    def recommended_poll_interval
      base_interval = 60 # Default: 60 seconds
      multiplier = calculate_poll_multiplier(rate_limit_tracker.consumption_percent)
      (base_interval * multiplier).ceil
    end

    # Get summary of token usage across all projects
    # @return [Hash]
    def usage_summary
      status = rate_limit_tracker.current_status
      projects = projects_using_token

      {
        token_hash: token_hash,
        remaining: status[:remaining],
        limit: status[:limit],
        resets_at: status[:resets_at],
        consumption_percent: rate_limit_tracker.consumption_percent,
        project_count: projects.count,
        projects: projects,
        recommended_interval: recommended_poll_interval,
        threshold_exceeded: rate_limit_tracker.threshold_exceeded?
      }
    end

    class << self
      # Get manager for a token
      # @param token [String] GitHub access token
      # @return [TokenQuotaManager]
      def for_token(token)
        new(token)
      end

      # Sync project registrations from database
      # Call this periodically to keep project list accurate
      # @param token [String] GitHub access token
      def sync_projects_for_token(token)
        manager = new(token)

        # Find all projects that would use this token
        # This is a simplified version - in production you might want
        # to query projects more specifically
        project_ids = Project.joins(:user)
                             .where.not(repository_url: [nil, ""])
                             .where(users: { github_token: token })
                             .or(Project.joins(:user).where(users: { github_user_access_token: token }))
                             .pluck(:id)

        project_ids.each { |id| manager.register_project(id) }
        manager
      end
    end

    private

    def token_hash
      return "unauthenticated" if token.blank?

      Digest::SHA256.hexdigest(token)[0..15]
    end

    def projects_cache_key
      "github_token_projects:#{token_hash}"
    end

    def save_projects(projects)
      Rails.cache.write(projects_cache_key, projects.uniq, expires_in: PROJECT_CACHE_TTL)
    end

    def default_remaining
      token.present? ? 5000 : 60
    end

    def default_limit
      token.present? ? 5000 : 60
    end

    # Calculate poll interval multiplier based on consumption percentage
    # As consumption increases, polling slows down
    def calculate_poll_multiplier(consumption)
      return BASE_POLL_MULTIPLIER if consumption < 50

      if consumption < 70
        # 50-70%: slight slowdown (1.0 - 2.0x)
        1.0 + ((consumption - 50) / 20.0)
      elsif consumption < 85
        # 70-85%: moderate slowdown (2.0 - 5.0x)
        2.0 + ((consumption - 70) / 15.0 * 3.0)
      else
        # 85%+: aggressive slowdown (5.0 - 10.0x)
        [5.0 + ((consumption - 85) / 15.0 * 5.0), MAX_POLL_MULTIPLIER].min
      end
    end
  end
end
