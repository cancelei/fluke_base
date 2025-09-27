# Cloudflare Turnstile Configuration
#
# To get your Turnstile keys:
# 1. Go to https://dash.cloudflare.com/
# 2. Navigate to Turnstile in the sidebar
# 3. Create a new site
# 4. Copy the Site Key and Secret Key
# 5. Add them to your Rails credentials or environment variables

Rails.application.configure do
  # Turnstile configuration
  test_site_key = "1x00000000000000000000AA"
  test_secret_key = "1x0000000000000000000000000000000AA"

  site_key = Rails.application.credentials.turnstile&.dig(:site_key) || ENV["TURNSTILE_SITE_KEY"]
  secret_key = Rails.application.credentials.turnstile&.dig(:secret_key) || ENV["TURNSTILE_SECRET_KEY"]

  if Rails.env.test?
    site_key ||= test_site_key
    secret_key ||= test_secret_key
  end

  config.turnstile = {
    site_key: site_key,
    secret_key: secret_key
  }

  # Validate that keys are present
  if !Rails.env.test? && (config.turnstile[:site_key].blank? || config.turnstile[:secret_key].blank?)
    Rails.logger.warn "Turnstile keys not configured. Please set TURNSTILE_SITE_KEY and TURNSTILE_SECRET_KEY environment variables or add them to Rails credentials."
  end
end
