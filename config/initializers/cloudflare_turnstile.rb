# Cloudflare Turnstile Configuration
#
# Enable Turnstile in all environments except test when keys are configured.
# For development with dev.flukebase.me and staging.flukebase.me, Turnstile
# provides bot protection while still allowing local development to fall back
# to test keys if real keys aren't available.

RailsCloudflareTurnstile.configure do |c|
  # Get keys from credentials or environment variables
  site_key = Rails.application.credentials.turnstile&.dig(:site_key) || ENV["TURNSTILE_SITE_KEY"]
  secret_key = Rails.application.credentials.turnstile&.dig(:secret_key) || ENV["TURNSTILE_SECRET_KEY"]

  c.site_key = site_key
  c.secret_key = secret_key

  if Rails.env.test?
    # Test environment: disable Turnstile entirely
    c.enabled = false
    c.fail_open = true
  else
    # Development, staging, and production: enable if keys are configured
    keys_configured = site_key.present? && secret_key.present?
    c.enabled = keys_configured
    c.fail_open = Rails.env.development? # Graceful degradation only in development
  end
end
