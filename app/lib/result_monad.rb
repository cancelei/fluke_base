# frozen_string_literal: true

# Base module for dry-monads Result type integration
# Provides Success/Failure result types without Do notation
#
# Usage:
#   class MyService
#     include ResultMonad
#
#     def call
#       return failure_result(:validation_error, "Name is required") if name.blank?
#       Success(record)
#     end
#   end
#
module ResultMonad
  extend ActiveSupport::Concern

  included do
    include Dry::Monads[:result]
  end

  # Convenience method for creating failures with structured data
  # Uses different name to avoid collision with dry-monads' Failure method
  # @param code [Symbol] Error code for categorization
  # @param message [String] Human-readable error message
  # @param details [Hash] Optional additional error details
  # @return [Dry::Monads::Result::Failure]
  def failure_result(code, message = nil, **details)
    error_data = { code: code }
    error_data[:message] = message if message
    error_data.merge!(details) if details.any?
    Dry::Monads::Failure(error_data)
  end

  # Alias for simple Failure with just a value (for backward compatibility)
  # @param value [Object] The failure value
  # @return [Dry::Monads::Result::Failure]
  def simple_failure(value)
    Dry::Monads::Failure(value)
  end
end
