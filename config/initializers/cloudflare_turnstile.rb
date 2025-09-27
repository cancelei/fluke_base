RailsCloudflareTurnstile.configure do |c|
  # Get keys from credentials or environment variables
  site_key = Rails.application.credentials.turnstile&.dig(:site_key) || ENV["TURNSTILE_SITE_KEY"]
  secret_key = Rails.application.credentials.turnstile&.dig(:secret_key) || ENV["TURNSTILE_SECRET_KEY"]

  c.site_key = site_key
  c.secret_key = secret_key

  # Environment-specific configuration
  case Rails.env
  when "test", "development"
    # In test and development environments, disable Turnstile and allow requests to pass
    c.enabled = false
    c.fail_open = true
  else
    # Production and other environments: strict validation
    c.fail_open = false # Don't allow requests to pass if Turnstile fails
    c.enabled = site_key.present? && secret_key.present? # Enable if keys are configured
  end
end
