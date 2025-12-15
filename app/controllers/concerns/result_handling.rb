# frozen_string_literal: true

# Concern for handling dry-monads Result types in controllers
# Provides helpers for pattern matching on Success/Failure results
module ResultHandling
  extend ActiveSupport::Concern

  included do
    include Dry::Monads[:result]
  end

  # Handle a Result type with block syntax
  # @param result [Dry::Monads::Result] The result to handle
  # @yield [type, value] Block receives :success/:failure and the value/error
  # @example
  #   handle_result(@agreement.accept!) do |type, value|
  #     case type
  #     when :success then redirect_to value, notice: "Success!"
  #     when :failure then redirect_to @agreement, alert: value[:message]
  #     end
  #   end
  def handle_result(result)
    case result
    in Dry::Monads::Result::Success(value)
      yield(:success, value)
    in Dry::Monads::Result::Failure(error)
      yield(:failure, error)
    end
  end

  # Extract error message from a Failure result
  # @param error [Hash] The error hash from Failure
  # @return [String] Human-readable error message
  def error_message(error)
    return error if error.is_a?(String)
    return error[:message] if error.is_a?(Hash) && error[:message]

    "An error occurred"
  end

  # Check if result is a success
  # @param result [Dry::Monads::Result] The result to check
  # @return [Boolean]
  def result_success?(result)
    result.is_a?(Dry::Monads::Result::Success)
  end

  # Check if result is a failure
  # @param result [Dry::Monads::Result] The result to check
  # @return [Boolean]
  def result_failure?(result)
    result.is_a?(Dry::Monads::Result::Failure)
  end

  # Render turbo stream flash message for failures
  # @param message [String] The error message to display
  def render_turbo_flash_error(message)
    flash.now[:alert] = message
    render turbo_stream: turbo_stream.prepend(
      "flash_messages",
      partial: "shared/flash_message",
      locals: { type: "alert", message: message }
    )
  end
end
