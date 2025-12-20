# frozen_string_literal: true

module Ratings
  # TurboBoost Command for submitting user ratings
  # Handles optimistic UI updates with server validation and revert on failure
  #
  # Usage in view:
  #   <button data-turbo-command="Ratings::SubmitCommand#execute"
  #           data-user-id="123"
  #           data-rating-value="4">
  #
  class SubmitCommand < ApplicationCommand
    include Flashable

    MAX_RETRIES = 3

    def execute
      user_id = element_id(:userId)
      rating_value = element_id(:ratingValue)
      previous_value = element_id(:previousValue)

      return handle_validation_error("Invalid rating value") unless valid_rating?(rating_value)
      return handle_validation_error("User not found") unless user_id

      user = User.find_by(id: user_id)
      return handle_validation_error("User not found") unless user

      return handle_validation_error("You cannot rate yourself") if user == current_user

      submit_rating(user, rating_value, previous_value)
    rescue ActiveRecord::RecordInvalid => e
      handle_submission_error(e.message, user_id, previous_value)
    rescue ActiveRecord::RecordNotFound
      handle_submission_error("User not found", user_id, previous_value)
    rescue StandardError => e
      Rails.logger.error("Rating submission error: #{e.message}")
      handle_submission_error("Something went wrong", user_id, previous_value)
    end

    private

    def valid_rating?(value)
      value.present? && value.to_i.between?(1, 5)
    end

    def submit_rating(user, rating_value, previous_value)
      rating = user.rate!(rater: current_user, value: rating_value)

      if rating.persisted?
        handle_success_response(user, rating)
      else
        handle_submission_error("Failed to save rating", user.id, previous_value)
      end
    end

    def handle_success_response(user, rating)
      toast_success("Rating submitted!")

      # Update the rating display via Turbo Stream
      update_rating_display(user)

      # Mark state as successful
      state[:success] = true
      state[:rating] = rating.value
      state[:average] = user.average_rating
      state[:count] = user.rating_count
    end

    def update_rating_display(user)
      turbo_streams << turbo_stream.replace(
        "user_#{user.id}_rating",
        partial: "ratings/rating_display",
        locals: {
          user:,
          current_user:,
          show_controls: true
        }
      )
    end

    def handle_validation_error(message)
      toast_error(message)
      state[:error] = message
      state[:should_revert] = false # Don't revert for validation errors
      Failure(:validation_error, message)
    end

    def handle_submission_error(message, user_id, previous_value)
      toast_error(message)

      # Signal to client to revert the optimistic update
      state[:error] = message
      state[:should_revert] = true
      state[:revert_to] = previous_value
      state[:user_id] = user_id

      # Increment failure count in session for circuit breaker
      increment_failure_count(user_id)

      Failure(:submission_error, message)
    end

    def increment_failure_count(user_id)
      key = "rating_failures_#{current_user.id}_#{user_id}"
      current_count = controller.session[key].to_i
      controller.session[key] = current_count + 1

      # Check if we should disable rating (circuit breaker)
      if controller.session[key] >= MAX_RETRIES
        state[:disabled] = true
        state[:disabled_message] = "Rating temporarily disabled. Please try again later."
        toast_error("Rating temporarily disabled due to repeated failures.")
      end
    end
  end
end
