# frozen_string_literal: true

# TurboBoost Commands Configuration
# Commands allow declarative server method invocation from client events
# See: https://github.com/hopsoft/turbo_boost-commands

Rails.application.config.turbo_boost_commands.tap do |config|
  # Show browser alerts when commands abort (useful for debugging)
  config.alert_on_abort = Rails.env.development?

  # Show browser alerts when commands error (useful for debugging)
  config.alert_on_error = Rails.env.development?

  # Precompile TurboBoost JavaScript assets
  config.precompile_assets = true

  # Enable CSRF protection for commands (recommended)
  config.protect_from_forgery = true

  # Raise exceptions for invalid commands in development
  config.raise_on_invalid_command = Rails.env.development?

  # Enable state management (Server-State, Client-State, Page-State)
  # This allows reactive state to be shared between client and server
  config.resolve_state = true

  # Verify client requests (recommended for security)
  config.verify_client = true
end
