# frozen_string_literal: true

module Github
  # Tracks GitHub API rate limit state per token
  #
  # Provides proactive rate limit checking to prevent hitting GitHub's rate limits.
  # Uses caching to track rate limit state from API response headers.
  #
  # GitHub Rate Limits (as of 2025):
  # - Free accounts (OAuth/PAT): 5,000 requests/hour
  # - GitHub App installations: 5,000-12,500 requests/hour (scales with users/repos)
  # - Unauthenticated: 60 requests/hour
  #
  # Usage:
  #   tracker = Github::RateLimitTracker.new(token)
  #
  #   # Check before making request
  #   if tracker.can_make_request?
  #     # Make API call
  #     response = client.commits(repo)
  #     tracker.record_response(response)
  #   else
  #     # Wait or skip
  #     wait_time = tracker.wait_time_seconds
  #   end
  #
  class RateLimitTracker
    # Safety threshold - stop at 85% of rate limit to leave buffer
    THRESHOLD_PERCENT = 85

    # Cache TTL for rate limit state
    CACHE_TTL = 5.minutes

    # Default rate limits by auth type
    DEFAULT_LIMITS = {
      authenticated: 5_000,      # OAuth/PAT
      github_app: 5_000,         # Base for GitHub App (can scale higher)
      unauthenticated: 60
    }.freeze

    attr_reader :token

    # Initialize tracker for a specific token
    # @param token [String, nil] GitHub access token (nil for unauthenticated)
    def initialize(token)
      @token = token
    end

    # Check if we can safely make a request without exceeding rate limit threshold
    # @param cost [Integer] Number of API calls this operation will make (default: 1)
    # @return [Boolean] true if safe to proceed, false if at/near threshold
    def can_make_request?(cost = 1)
      status = current_status
      return true if status[:remaining].nil? # No cached data, allow request

      threshold = threshold_remaining(status[:limit])
      (status[:remaining] - cost) >= threshold
    end

    # Check if we're currently rate limited (at 0 remaining)
    # @return [Boolean] true if rate limited
    def rate_limited?
      status = current_status
      return false if status[:remaining].nil?

      status[:remaining] <= 0
    end

    # Get current rate limit status from cache
    # @return [Hash] { limit:, remaining:, resets_at: }
    def current_status
      cached = Rails.cache.read(cache_key)
      return default_status if cached.nil?

      cached
    end

    # Record rate limit headers from an API response
    # @param response [Sawyer::Response, Hash] Response object with headers
    def record_response(response)
      headers = extract_headers(response)
      return if headers.empty?

      status = {
        limit: headers[:limit],
        remaining: headers[:remaining],
        resets_at: headers[:resets_at],
        recorded_at: Time.current
      }

      Rails.cache.write(cache_key, status, expires_in: CACHE_TTL)
      log_rate_limit_status(status)

      status
    end

    # Record rate limit from Octokit rate_limit response
    # @param rate_limit [Sawyer::Resource] Octokit rate_limit response
    def record_from_rate_limit_check(rate_limit)
      status = {
        limit: rate_limit.limit,
        remaining: rate_limit.remaining,
        resets_at: Time.at(rate_limit.resets_at.to_i),
        recorded_at: Time.current
      }

      Rails.cache.write(cache_key, status, expires_in: CACHE_TTL)
      log_rate_limit_status(status)

      status
    end

    # Calculate seconds to wait until safe to proceed
    # @return [Integer] Seconds to wait (0 if not rate limited)
    def wait_time_seconds
      status = current_status
      return 0 if status[:resets_at].nil?
      return 0 if can_make_request?

      wait = (status[:resets_at] - Time.current).to_i
      [wait + 1, 0].max # Add 1 second buffer, minimum 0
    end

    # Get the threshold value (remaining requests that trigger throttling)
    # @param limit [Integer] Total rate limit
    # @return [Integer] Threshold value
    def threshold_remaining(limit)
      return 0 if limit.nil? || limit <= 0

      ((100 - THRESHOLD_PERCENT) / 100.0 * limit).ceil
    end

    # Force refresh rate limit status from GitHub API
    # @param client [Octokit::Client] Authenticated client
    # @return [Hash] Updated status
    def refresh_from_api(client)
      rate_limit = client.rate_limit
      record_from_rate_limit_check(rate_limit)
    rescue Octokit::Error => e
      Rails.logger.warn "[RateLimitTracker] Failed to refresh rate limit: #{e.message}"
      current_status
    end

    # Get percentage of rate limit consumed
    # @return [Float] Percentage consumed (0-100)
    def consumption_percent
      status = current_status
      return 0.0 if status[:limit].nil? || status[:limit] <= 0
      return 0.0 if status[:remaining].nil? # No data yet, assume 0% consumed

      ((status[:limit] - status[:remaining]).to_f / status[:limit] * 100).round(2)
    end

    # Check if we're approaching the threshold (warning zone)
    # @return [Boolean] true if in warning zone (75-85% consumed)
    def approaching_threshold?
      percent = consumption_percent
      percent >= 75 && percent < THRESHOLD_PERCENT
    end

    # Check if we've exceeded threshold (stop zone)
    # @return [Boolean] true if at or above threshold
    def threshold_exceeded?
      consumption_percent >= THRESHOLD_PERCENT
    end

    class << self
      # Get tracker for a token, using cached instance if available
      # @param token [String, nil] GitHub access token
      # @return [RateLimitTracker]
      def for_token(token)
        new(token)
      end

      # Check if a token can make requests (convenience method)
      # @param token [String, nil] GitHub access token
      # @param cost [Integer] Number of API calls
      # @return [Boolean]
      def can_make_request?(token, cost = 1)
        for_token(token).can_make_request?(cost)
      end
    end

    private

    def cache_key
      token_hash = token.present? ? Digest::SHA256.hexdigest(token)[0..15] : "unauthenticated"
      "github_rate_limit:#{token_hash}"
    end

    def default_status
      limit = token.present? ? DEFAULT_LIMITS[:authenticated] : DEFAULT_LIMITS[:unauthenticated]
      {
        limit: limit,
        remaining: nil, # Unknown until first API response
        resets_at: nil,
        recorded_at: nil
      }
    end

    def extract_headers(response)
      headers = {}

      # Handle different response types
      raw_headers = case response
                    when Sawyer::Response
                      response.headers
                    when Hash
                      response[:headers] || response["headers"] || {}
                    else
                      return headers
                    end

      # Extract rate limit headers (case-insensitive)
      limit = raw_headers["x-ratelimit-limit"] || raw_headers["X-RateLimit-Limit"]
      remaining = raw_headers["x-ratelimit-remaining"] || raw_headers["X-RateLimit-Remaining"]
      reset = raw_headers["x-ratelimit-reset"] || raw_headers["X-RateLimit-Reset"]

      headers[:limit] = limit.to_i if limit
      headers[:remaining] = remaining.to_i if remaining
      headers[:resets_at] = Time.at(reset.to_i) if reset

      headers
    end

    def log_rate_limit_status(status)
      percent = status[:limit] && status[:limit] > 0 ?
        ((status[:limit] - status[:remaining]).to_f / status[:limit] * 100).round(1) : 0

      level = if percent >= THRESHOLD_PERCENT
                :warn
              elsif percent >= 75
                :info
              else
                :debug
              end

      message = "[RateLimitTracker] Rate limit: #{status[:remaining]}/#{status[:limit]} " \
                "(#{percent}% consumed, resets at #{status[:resets_at]&.strftime('%H:%M:%S')})"

      Rails.logger.public_send(level, message)
    end
  end
end
