# frozen_string_literal: true

# OmniAuth Configuration
#
# This configures OmniAuth for GitHub App OAuth integration.
# The omniauth-rails_csrf_protection gem handles CSRF token verification.

# Only allow POST requests for OAuth (security best practice)
OmniAuth.config.allowed_request_methods = [:post]

# Silence GET request warnings since we only use POST
OmniAuth.config.silence_get_warning = true

# Handle OAuth failures gracefully
# We must set the Devise mapping before calling the controller
# because bypassing the router means Devise context isn't set
OmniAuth.config.on_failure = proc do |env|
  # Set Devise mapping for the user scope
  env["devise.mapping"] = Devise.mappings[:user]

  # Store error info in session for display
  session_options = env[Rack::RACK_SESSION_OPTIONS]
  session_options[:skip] = false if session_options

  # Call the failure action with proper Devise context
  Users::OmniauthCallbacksController.action(:failure).call(env)
end
