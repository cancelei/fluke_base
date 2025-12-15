# frozen_string_literal: true

# RSpec matchers for dry-monads Result types
# Provides convenient matchers for testing Success and Failure results

require "dry/monads"

RSpec::Matchers.define :be_success do |expected_value = nil|
  match do |result|
    return false unless result.is_a?(Dry::Monads::Result::Success)
    return true if expected_value.nil?

    result.value! == expected_value
  end

  failure_message do |result|
    if result.is_a?(Dry::Monads::Result::Success)
      "expected Success(#{expected_value.inspect}) but got Success(#{result.value!.inspect})"
    else
      "expected Success but got Failure(#{result.failure.inspect})"
    end
  end

  failure_message_when_negated do |result|
    "expected not to be Success but got Success(#{result.value!.inspect})"
  end

  description do
    expected_value ? "be Success(#{expected_value.inspect})" : "be Success"
  end
end

RSpec::Matchers.define :be_failure do |expected_code = nil|
  match do |result|
    return false unless result.is_a?(Dry::Monads::Result::Failure)
    return true if expected_code.nil?

    error = result.failure
    if error.is_a?(Hash)
      error[:code] == expected_code
    else
      error == expected_code
    end
  end

  failure_message do |result|
    if result.is_a?(Dry::Monads::Result::Failure)
      error = result.failure
      code = error.is_a?(Hash) ? error[:code] : error
      "expected Failure(#{expected_code.inspect}) but got Failure(#{code.inspect})"
    else
      "expected Failure but got Success(#{result.value!.inspect})"
    end
  end

  failure_message_when_negated do |result|
    "expected not to be Failure but got Failure(#{result.failure.inspect})"
  end

  description do
    expected_code ? "be Failure(#{expected_code.inspect})" : "be Failure"
  end
end

RSpec::Matchers.define :be_failure_with_message do |expected_message|
  match do |result|
    return false unless result.is_a?(Dry::Monads::Result::Failure)

    error = result.failure
    if error.is_a?(Hash)
      error[:message] == expected_message || error[:message]&.include?(expected_message.to_s)
    else
      error.to_s.include?(expected_message.to_s)
    end
  end

  failure_message do |result|
    if result.is_a?(Dry::Monads::Result::Failure)
      error = result.failure
      message = error.is_a?(Hash) ? error[:message] : error
      "expected Failure with message containing '#{expected_message}' but got '#{message}'"
    else
      "expected Failure but got Success(#{result.value!.inspect})"
    end
  end

  description do
    "be Failure with message containing '#{expected_message}'"
  end
end

# Helper method to extract value from Success
# @param result [Dry::Monads::Result] The result to unwrap
# @return [Object] The success value
# @raise [Dry::Monads::UnwrapError] If result is a Failure
def unwrap_success(result)
  result.value!
end

# Helper method to extract error from Failure
# @param result [Dry::Monads::Result] The result to unwrap
# @return [Object] The failure error
# @raise [Dry::Monads::UnwrapError] If result is a Success
def unwrap_failure(result)
  result.failure
end
