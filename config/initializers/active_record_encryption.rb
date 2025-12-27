# frozen_string_literal: true

# Configure Active Record Encryption from environment variables
# This is required for encrypting sensitive fields like GitHub tokens
#
# Generate keys with: rails db:encryption:init
# Then set these environment variables in production:
#   - ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
#   - ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
#   - ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
#
# NOTE: We must call ActiveRecord::Encryption.configure() explicitly to avoid
# a timing issue in eager loading mode where models load before after_initialize runs.
# See: https://github.com/rails/rails/issues/50604

if ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].present?
  Rails.application.config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
  Rails.application.config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
  Rails.application.config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

  # Force immediate configuration to ensure encryption is ready before models load
  ActiveRecord::Encryption.configure(
    primary_key: ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"],
    deterministic_key: ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"],
    key_derivation_salt: ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
  )
end
