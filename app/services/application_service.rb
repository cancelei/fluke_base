# frozen_string_literal: true

# Base class for all service objects
# Provides Result monad functionality for explicit success/failure handling
#
# Usage:
#   class MyService < ApplicationService
#     def initialize(record)
#       @record = record
#     end
#
#     def call
#       return failure_result(:invalid, "Record is invalid") unless @record.valid?
#       Success(@record)
#     end
#   end
#
#   # Using the service:
#   result = MyService.call(record)
#   result.success? # => true or false
#
class ApplicationService
  include ResultMonad

  # Class-level call method for convenient instantiation
  # @return [Dry::Monads::Result]
  def self.call(...)
    new(...).call
  end
end
