# frozen_string_literal: true

module Milestones
  # Command to apply an AI enhancement to a milestone
  # Updates the milestone description with the enhanced version
  # @return [Dry::Monads::Result] Success(milestone) or Failure(error)
  #
  # Usage in view:
  #   <button data-turbo-command="Milestones::ApplyEnhancementCommand#execute"
  #           data-enhancement-id="<%= enhancement.id %>">
  #     Apply Enhancement
  #   </button>
  class ApplyEnhancementCommand < ApplicationCommand
    def execute
      enhancement_id = element_data(:enhancementId)

      if enhancement_id.blank?
        flash_error("Enhancement ID not found.")
        return failure_result(:missing_id, "Enhancement ID not found.")
      end

      enhancement = MilestoneEnhancement.find(enhancement_id)
      milestone = enhancement.milestone

      unless enhancement.successful? && enhancement.enhanced_description.present?
        flash_error("Enhancement is not ready to be applied.")
        return failure_result(:not_ready, "Enhancement is not ready to be applied.")
      end

      if milestone.update(description: enhancement.enhanced_description)
        update_frame("milestone_description", partial: "milestones/description", locals: { milestone: milestone })
        clear_frame("ai-suggestion-container")
        flash_notice("Enhancement applied successfully!")
        Success(milestone)
      else
        flash_error("Failed to apply enhancement.")
        failure_result(:update_failed, "Failed to apply enhancement.", errors: milestone.errors)
      end
    rescue ActiveRecord::RecordNotFound
      flash_error("Enhancement not found.")
      failure_result(:not_found, "Enhancement not found.")
    end
  end
end
