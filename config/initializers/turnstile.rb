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
  config.turnstile = {
    site_key: Rails.application.credentials.turnstile&.dig(:site_key) || ENV["TURNSTILE_SITE_KEY"],
    secret_key: Rails.application.credentials.turnstile&.dig(:secret_key) || ENV["TURNSTILE_SECRET_KEY"]
  }

  # Validate that keys are present
  if config.turnstile[:site_key].blank? || config.turnstile[:secret_key].blank?
    Rails.logger.warn "Turnstile keys not configured. Please set TURNSTILE_SITE_KEY and TURNSTILE_SECRET_KEY environment variables or add them to Rails credentials."
  end
end
