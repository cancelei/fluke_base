# Rack::Attack configuration for rate limiting and security
# Protects against bots, scrapers, and malicious traffic

module Rack
  class Attack
    ### Configure Cache ###

    # Use Rails cache store (Solid Cache)
    Rack::Attack.cache.store = Rails.cache

    ### Safelist ###

    # Always allow requests from localhost (development/testing)
    Rack::Attack.safelist("allow-localhost") do |req|
      ["127.0.0.1", "::1"].include?(req.ip)
    end

    # Allow health checks
    Rack::Attack.safelist("allow-healthchecks") do |req|
      req.path == "/up" || req.path.start_with?("/test/")
    end

    ### Throttles ###

    # General throttle: 60 requests per minute per IP
    Rack::Attack.throttle("req/ip/minute", limit: 60, period: 1.minute, &:ip)

    # General throttle: 500 requests per hour per IP
    Rack::Attack.throttle("req/ip/hour", limit: 500, period: 1.hour, &:ip)

    # Authentication endpoints - strict limits to prevent credential stuffing
    Rack::Attack.throttle("auth/ip", limit: 5, period: 20.minutes) do |req|
      if (req.path.start_with?("/users/sign_in", "/users/sign_up") ||
         req.path.include?("password")) && req.post?
        req.ip
      end
    end

    # Project creation - prevent spam
    Rack::Attack.throttle("projects/ip", limit: 10, period: 1.hour) do |req|
      req.ip if req.path.include?("/projects") && req.post?
    end

    # Agreement creation - prevent abuse
    Rack::Attack.throttle("agreements/ip", limit: 10, period: 1.hour) do |req|
      req.ip if req.path.include?("/agreements") && req.post?
    end

    # Form submissions - prevent spam
    Rack::Attack.throttle("forms/ip", limit: 20, period: 1.hour) do |req|
      if (req.path.include?("/messages") ||
          req.path.include?("/time_entries")) && req.post?
        req.ip
      end
    end

    # Turnstile verification endpoint
    Rack::Attack.throttle("turnstile/ip", limit: 30, period: 1.hour) do |req|
      req.ip if req.path.include?("/turnstile")
    end

    ### Custom Response ###

    # Customize the response for throttled requests
    Rack::Attack.throttled_responder = lambda do |req|
      match_data = req.env["rack.attack.match_data"]
      now = match_data[:epoch_time]

      headers = {
        "RateLimit-Limit" => match_data[:limit].to_s,
        "RateLimit-Remaining" => "0",
        "RateLimit-Reset" => (now + (match_data[:period] - (now % match_data[:period]))).to_s,
        "Content-Type" => "text/plain"
      }

      [429, headers, ["Rate limit exceeded. Please try again later.\n"]]
    end

    ### Logging ###

    # Log blocked and throttled requests
    ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _request_id, payload|
      req = payload[:request]

      case req.env["rack.attack.match_type"]
      when :throttle
        matched_rule = req.env["rack.attack.matched"]
        Rails.logger.warn "[Rack::Attack][THROTTLED] #{req.ip} - #{req.path} - #{matched_rule}"
      when :blocklist
        matched_rule = req.env["rack.attack.matched"]
        Rails.logger.error "[Rack::Attack][BANNED] #{req.ip} - #{req.path} - #{matched_rule}"
      when :safelist
        Rails.logger.debug "[Rack::Attack][ALLOWED] #{req.ip} - #{req.path}"
      end
    end
  end
end
