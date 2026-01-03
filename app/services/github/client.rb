# frozen_string_literal: true

module Github
  # Thin wrapper around Octokit for GitHub API interactions
  #
  # Provides consistent error handling and Result monad returns
  # for all GitHub API calls. Automatically tracks rate limit headers
  # from all responses.
  #
  # Usage:
  #   client = Github::Client.new(access_token: "ghp_xxx")
  #
  #   # Check rate limit before making requests
  #   if client.can_proceed?
  #     result = client.commits("owner/repo", sha: "main", per_page: 100)
  #     if result.success?
  #       commits = result.value!
  #     end
  #   else
  #     wait_time = client.rate_limit_tracker.wait_time_seconds
  #   end
  #
  class Client < Base
    attr_reader :octokit, :access_token, :rate_limit_tracker

    # Initialize the client
    # @param access_token [String, nil] GitHub personal access token
    def initialize(access_token: nil)
      @access_token = access_token
      @octokit = build_client(access_token)
      @rate_limit_tracker = RateLimitTracker.new(access_token)
    end

    # Check if we can safely proceed with API requests (under 85% threshold)
    # @param cost [Integer] Number of API calls planned
    # @return [Boolean]
    def can_proceed?(cost = 1)
      rate_limit_tracker.can_make_request?(cost)
    end

    # Check if rate limit threshold is exceeded
    # @return [Boolean]
    def threshold_exceeded?
      rate_limit_tracker.threshold_exceeded?
    end

    # Fetch commits from a repository
    # @param repo_path [String] Repository path (owner/repo)
    # @param options [Hash] Options passed to Octokit (sha, per_page, page, etc.)
    # @return [Dry::Monads::Result] Success with commits or Failure with error
    def commits(repo_path, options = {})
      with_api_error_handling do
        result = octokit.commits(repo_path, options)
        record_rate_limit_from_response
        Success(result)
      end
    end

    # Fetch a single commit with full details
    # @param repo_path [String] Repository path (owner/repo)
    # @param sha [String] Commit SHA
    # @return [Dry::Monads::Result] Success with commit or Failure with error
    def commit(repo_path, sha)
      with_api_error_handling do
        result = octokit.commit(repo_path, sha)
        record_rate_limit_from_response
        Success(result)
      end
    end

    # Fetch branches from a repository
    # @param repo_path [String] Repository path (owner/repo)
    # @return [Dry::Monads::Result] Success with branches or Failure with error
    def branches(repo_path)
      with_api_error_handling do
        result = octokit.branches(repo_path)
        record_rate_limit_from_response
        Success(result)
      end
    end

    # Get the last response from Octokit (for pagination)
    # @return [Sawyer::Response, nil]
    def last_response
      octokit.last_response
    end

    # Check rate limit status and update tracker
    # @return [Hash] Rate limit information
    def rate_limit
      rate_limit_response = octokit.rate_limit
      rate_limit_tracker.record_from_rate_limit_check(rate_limit_response)

      {
        limit: rate_limit_response.limit,
        remaining: rate_limit_response.remaining,
        resets_at: Time.at(rate_limit_response.resets_at.to_i)
      }
    rescue Octokit::Error
      { limit: 0, remaining: 0, resets_at: Time.current }
    end

    # Refresh rate limit status from API
    # @return [Hash] Updated rate limit status
    def refresh_rate_limit
      rate_limit_tracker.refresh_from_api(octokit)
    end

    private

    # Record rate limit headers from the last API response
    def record_rate_limit_from_response
      return unless octokit.last_response

      rate_limit_tracker.record_response(octokit.last_response)
    end
  end
end
