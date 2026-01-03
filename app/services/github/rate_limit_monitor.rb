# frozen_string_literal: true

module Github
  # Monitors and logs GitHub API rate limit consumption
  #
  # Provides structured logging, aggregated metrics, and alerting
  # for rate limit status across all tokens.
  #
  # Features:
  # - Structured logging with consistent format
  # - Aggregated metrics per token
  # - Alert thresholds for proactive monitoring
  # - Daily/hourly usage summaries
  #
  # Usage:
  #   # Log a rate limit event
  #   Github::RateLimitMonitor.log_api_call(token, endpoint: "commits", cost: 1)
  #
  #   # Get usage summary
  #   Github::RateLimitMonitor.usage_summary(token)
  #
  #   # Check for alerts
  #   alerts = Github::RateLimitMonitor.check_alerts
  #
  class RateLimitMonitor
    # Alert threshold percentages
    WARNING_THRESHOLD = 70
    CRITICAL_THRESHOLD = 85

    # Cache keys
    METRICS_PREFIX = "github_rate_limit_metrics"

    class << self
      # Log an API call with rate limit tracking
      # @param token [String] GitHub access token
      # @param endpoint [String] API endpoint called
      # @param cost [Integer] Number of API calls consumed
      # @param response_headers [Hash] Optional response headers
      def log_api_call(token, endpoint:, cost: 1, response_headers: nil)
        tracker = RateLimitTracker.new(token)

        # Update tracker if we have response headers
        tracker.record_response({ headers: response_headers }) if response_headers

        status = tracker.current_status
        consumption = tracker.consumption_percent

        # Increment call counter
        increment_call_count(token, cost)

        # Log based on consumption level
        log_consumption(token, endpoint, cost, status, consumption)

        # Check and log alerts
        check_and_log_alerts(token, consumption, status)
      end

      # Get usage metrics for a token
      # @param token [String] GitHub access token
      # @return [Hash] Usage metrics
      def usage_summary(token)
        tracker = RateLimitTracker.new(token)
        status = tracker.current_status

        hourly_calls = get_call_count(token, :hour)
        daily_calls = get_call_count(token, :day)

        {
          token_hash: token_hash(token),
          current_status: status,
          consumption_percent: tracker.consumption_percent,
          threshold_exceeded: tracker.threshold_exceeded?,
          approaching_threshold: tracker.approaching_threshold?,
          hourly_calls:,
          daily_calls:,
          limit_per_hour: status[:limit] || 5000,
          remaining: status[:remaining],
          resets_at: status[:resets_at],
          wait_time_seconds: tracker.wait_time_seconds
        }
      end

      # Check all tracked tokens for alerts
      # @return [Array<Hash>] Array of alert objects
      def check_alerts
        alerts = []
        tracked_tokens.each do |token_hash|
          # We can't reconstruct the full token from hash,
          # so we rely on cached status
          status = Rails.cache.read("github_rate_limit:#{token_hash}")
          next unless status

          consumption = calculate_consumption(status)

          if consumption >= CRITICAL_THRESHOLD
            alerts << build_alert(:critical, token_hash, consumption, status)
          elsif consumption >= WARNING_THRESHOLD
            alerts << build_alert(:warning, token_hash, consumption, status)
          end
        end

        alerts
      end

      # Log a summary of all rate limit statuses (for periodic reporting)
      def log_summary
        alerts = check_alerts
        tracked = tracked_tokens.count

        if alerts.any?
          critical = alerts.count { |a| a[:level] == :critical }
          warning = alerts.count { |a| a[:level] == :warning }

          Rails.logger.warn "[RateLimitMonitor] Summary: #{tracked} tokens tracked, " \
                            "#{critical} critical, #{warning} warning alerts"

          alerts.each do |alert|
            Rails.logger.public_send(alert[:level] == :critical ? :error : :warn,
                                     "[RateLimitMonitor] #{alert[:level].upcase}: " \
                                     "Token #{alert[:token_hash]} at #{alert[:consumption]}% " \
                                     "(#{alert[:remaining]}/#{alert[:limit]})")
          end
        else
          Rails.logger.info "[RateLimitMonitor] Summary: #{tracked} tokens tracked, all healthy"
        end
      end

      # Register a token for monitoring
      # @param token [String] GitHub access token
      def register_token(token)
        hash = token_hash(token)
        tokens = tracked_tokens
        tokens << hash unless tokens.include?(hash)
        Rails.cache.write(tracked_tokens_key, tokens, expires_in: 24.hours)
      end

      # Get list of tracked token hashes
      # @return [Array<String>] Token hashes
      def tracked_tokens
        Rails.cache.read(tracked_tokens_key) || []
      end

      private

      def token_hash(token)
        return "unauthenticated" if token.blank?

        Digest::SHA256.hexdigest(token)[0..15]
      end

      def tracked_tokens_key
        "#{METRICS_PREFIX}:tracked_tokens"
      end

      def call_count_key(token, period)
        hash = token_hash(token)
        case period
        when :hour
          "#{METRICS_PREFIX}:calls:#{hash}:#{Time.current.strftime('%Y%m%d%H')}"
        when :day
          "#{METRICS_PREFIX}:calls:#{hash}:#{Time.current.strftime('%Y%m%d')}"
        end
      end

      def increment_call_count(token, count = 1)
        register_token(token)

        # Increment hourly counter
        hourly_key = call_count_key(token, :hour)
        Rails.cache.increment(hourly_key, count, expires_in: 2.hours)

        # Increment daily counter
        daily_key = call_count_key(token, :day)
        Rails.cache.increment(daily_key, count, expires_in: 25.hours)
      end

      def get_call_count(token, period)
        Rails.cache.read(call_count_key(token, period)).to_i
      end

      def log_consumption(token, endpoint, cost, status, consumption)
        hash = token_hash(token)

        message = "[RateLimitMonitor] API call: #{endpoint} (cost: #{cost}) " \
                  "token: #{hash} remaining: #{status[:remaining]}/#{status[:limit]} " \
                  "(#{consumption}% consumed)"

        level = if consumption >= CRITICAL_THRESHOLD
                  :warn
        elsif consumption >= WARNING_THRESHOLD
                  :info
        else
                  :debug
        end

        Rails.logger.public_send(level, message)
      end

      def check_and_log_alerts(token, consumption, status)
        hash = token_hash(token)

        if consumption >= CRITICAL_THRESHOLD
          Rails.logger.error "[RateLimitMonitor] CRITICAL: Token #{hash} at #{consumption}% - " \
                             "only #{status[:remaining]} requests remaining, resets at #{status[:resets_at]}"
        elsif consumption >= WARNING_THRESHOLD
          Rails.logger.warn "[RateLimitMonitor] WARNING: Token #{hash} approaching threshold at #{consumption}%"
        end
      end

      def build_alert(level, token_hash, consumption, status)
        {
          level:,
          token_hash:,
          consumption: consumption.round(1),
          remaining: status[:remaining],
          limit: status[:limit],
          resets_at: status[:resets_at],
          created_at: Time.current
        }
      end

      def calculate_consumption(status)
        return 0.0 if status[:limit].nil? || status[:limit] <= 0
        return 100.0 if status[:remaining].nil?

        ((status[:limit] - status[:remaining]).to_f / status[:limit] * 100)
      end
    end
  end
end
