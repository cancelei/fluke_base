# frozen_string_literal: true

# Base command class for all TurboBoost commands
# Commands are triggered by data-turbo-command attributes on HTML elements
# and execute server-side logic with automatic Turbo Stream responses
#
# Commands return Result types (Success/Failure) for explicit outcome handling
# while maintaining compatibility with state hash and flash patterns
class ApplicationCommand < TurboBoost::Commands::Command
  include Flashable
  include MultiFrameUpdatable
  include StateManageable
  include ResultMonad

  protected

  # Access the current authenticated user
  def current_user
    controller.current_user
  end

  # Find a project accessible by the current user
  def find_project(id = params[:project_id])
    @project ||= current_user.projects.find(id)
  end

  # Find a milestone within a project
  def find_milestone(project_id:, milestone_id:)
    find_project(project_id).milestones.find(milestone_id)
  end

  # Standard error handling - logs, shows flash error, and returns Failure
  # @param message [String] Error message to display
  # @param exception [Exception, nil] Optional exception for logging
  # @param code [Symbol] Error code for categorization (default: :error)
  # @return [Dry::Monads::Result::Failure]
  def handle_error(message, exception: nil, code: :error)
    Rails.logger.error("Command error: #{message}")
    Rails.logger.error(exception.backtrace.first(10).join("\n")) if exception
    flash_error(message)
    state[:error] = message
    Failure(code, message)
  end

  # Standard success handling - shows flash notice and returns Success
  # @param message [String] Success message to display
  # @param data [Object, nil] Optional data to wrap in Success
  # @return [Dry::Monads::Result::Success]
  def handle_success(message, data = nil)
    flash_notice(message)
    state[:success] = message
    Success(data || message)
  end

  # Get data attribute from the triggering element
  # TurboBoost converts data-foo-bar to foo_bar method on element.data
  def element_data(key)
    method_name = key.to_s.underscore
    element.data&.public_send(method_name)
  end

  # Get integer ID from element data attribute
  def element_id(key)
    element_data(key)&.to_i
  end

  # Wrap record not found errors with Failure result
  # @yield Block that may raise ActiveRecord::RecordNotFound
  # @return [Dry::Monads::Result]
  def with_record_not_found_handling
    yield
  rescue ActiveRecord::RecordNotFound => e
    handle_error("Record not found", exception: e, code: :not_found)
  end
end
