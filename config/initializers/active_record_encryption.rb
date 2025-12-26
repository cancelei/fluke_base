# frozen_string_literal: true

# Configure Active Record Encryption from environment variables
# This is required for encrypting sensitive fields like GitHub tokens
#
# Generate keys with: rails db:encryption:init
# Then set these environment variables in production:
#   - ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
#   - ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
#   - ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT

if ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].present?
  Rails.application.config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
  Rails.application.config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
  Rails.application.config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
end
