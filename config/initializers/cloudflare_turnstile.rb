RailsCloudflareTurnstile.configure do |c|
  # Get keys from credentials or environment variables
  site_key = Rails.application.credentials.turnstile&.dig(:site_key) || ENV["TURNSTILE_SITE_KEY"]
  secret_key = Rails.application.credentials.turnstile&.dig(:secret_key) || ENV["TURNSTILE_SECRET_KEY"]

  c.site_key = site_key
  c.secret_key = secret_key
  c.fail_open = Rails.env.development? # Allow requests to pass in development if Turnstile fails
  c.enabled = !Rails.env.development? && site_key.present? && secret_key.present? # Only enable if keys are configured
end
