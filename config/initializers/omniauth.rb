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
OmniAuth.config.on_failure = proc do |env|
  Users::OmniauthCallbacksController.action(:failure).call(env)
end
