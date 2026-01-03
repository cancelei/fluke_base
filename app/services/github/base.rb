# frozen_string_literal: true

module Github
  # Base class for all GitHub services
  # Provides shared functionality for GitHub API interactions
  #
  # Features:
  # - Proactive rate limit checking (85% threshold)
  # - Automatic rate limit header tracking
  # - Consistent error handling with Result monads
  #
  # Usage:
  #   class Github::MyService < Github::Base
  #     def initialize(project:, access_token:)
  #       @project = project
  #       @access_token = access_token
  #       @client = build_client(access_token)
  #     end
  #   end
  #
  class Base < ApplicationService
    protected

    # Build an Octokit client with optional authentication
    # @param access_token [String, nil] GitHub personal access token
    # @return [Octokit::Client] Configured GitHub API client
    def build_client(access_token = nil)
      @current_access_token = access_token
      if access_token.present?
        Octokit::Client.new(access_token:)
      else
        Octokit::Client.new
      end
    end

    # Get rate limit tracker for the current token
    # @return [RateLimitTracker, nil]
    def rate_limit_tracker
      return nil unless defined?(@current_access_token)

      @rate_limit_tracker ||= RateLimitTracker.new(@current_access_token)
    end

    # Check if we can safely make API requests
    # @param cost [Integer] Estimated number of API calls
    # @return [Boolean]
    def can_make_request?(cost = 1)
      return true unless rate_limit_tracker

      rate_limit_tracker.can_make_request?(cost)
    end

    # Check if rate limit threshold is exceeded
    # @return [Boolean]
    def rate_limit_exceeded?
      return false unless rate_limit_tracker

      rate_limit_tracker.threshold_exceeded?
    end

    # Extract repository path from various URL formats
    # Supports:
    #   - Full URL: https://github.com/owner/repo
    #   - Full URL with .git: https://github.com/owner/repo.git
    #   - Short format: owner/repo
    #
    # @param url [String] Repository URL or path
    # @return [String] Repository path in "owner/repo" format
    def extract_repo_path(url)
      return nil if url.blank?

      if url.include?("github.com/")
        url.split("github.com/").last.gsub(/\.git$/, "")
      else
        url.gsub(/\.git$/, "")
      end
    end

    # Handle GitHub API rate limiting with exponential backoff
    # @param error [Octokit::TooManyRequests] Rate limit error
    def handle_rate_limit(error)
      reset_time = error.response_headers["x-ratelimit-reset"].to_i
      wait_time = [reset_time - Time.now.to_i + 1, 1].max
      Rails.logger.warn "[Github] API rate limit reached. Waiting #{wait_time} seconds..."

      # Update tracker with rate limit info from error response
      if rate_limit_tracker && error.response_headers
        rate_limit_tracker.record_response({ headers: error.response_headers })
      end

      sleep(wait_time)
    end

    # Wrap API calls with error handling and optional proactive rate limit check
    # @param check_rate_limit [Boolean] Whether to check rate limit before proceeding
    # @param estimated_cost [Integer] Estimated API calls for this operation
    # @yield Block containing API call
    # @return [Dry::Monads::Result] Success with result or Failure with error details
    def with_api_error_handling(check_rate_limit: false, estimated_cost: 1)
      # Proactive rate limit check
      if check_rate_limit && !can_make_request?(estimated_cost)
        tracker = rate_limit_tracker
        wait_time = tracker&.wait_time_seconds || 0
        log("[RateLimit] Proactive block: #{tracker&.consumption_percent}% consumed, waiting #{wait_time}s", level: :warn)
        return failure_result(:rate_limit_exceeded, "Rate limit threshold (85%) exceeded. Resets in #{wait_time}s")
      end

      yield
    rescue Octokit::TooManyRequests => e
      handle_rate_limit(e)
      retry
    rescue Octokit::NotFound => e
      failure_result(:not_found, e.message, exception_class: e.class.name)
    rescue Octokit::Unauthorized => e
      failure_result(:unauthorized, e.message, exception_class: e.class.name)
    rescue Octokit::Forbidden => e
      failure_result(:forbidden, e.message, exception_class: e.class.name)
    rescue Octokit::Error => e
      Rails.logger.error "[Github] API Error: #{e.message}"
      failure_result(:api_error, e.message, exception_class: e.class.name)
    end

    # Log with consistent prefix for GitHub operations
    # @param message [String] Log message
    # @param level [Symbol] Log level (:info, :warn, :error)
    def log(message, level: :info)
      Rails.logger.public_send(level, "[Github] #{message}")
    end
  end
end
