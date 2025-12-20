# frozen_string_literal: true

module Milestones
  # Command to revert a milestone to its original description
  # Undoes the effect of applying an AI enhancement
  # @return [Dry::Monads::Result] Success(milestone) or Failure(error)
  #
  # Usage in view:
  #   <button data-turbo-command="Milestones::RevertEnhancementCommand#execute"
  #           data-enhancement-id="<%= enhancement.id %>">
  #     Revert to Original
  #   </button>
  class RevertEnhancementCommand < ApplicationCommand
    def execute
      enhancement_id = element_data(:enhancementId)

      if enhancement_id.blank?
        flash_error("Enhancement ID not found.")
        return failure_result(:missing_id, "Enhancement ID not found.")
      end

      enhancement = MilestoneEnhancement.find(enhancement_id)
      milestone = enhancement.milestone

      if milestone.update(description: enhancement.original_description)
        update_frame("milestone_description", partial: "milestones/description", locals: { milestone: })
        clear_frame("ai-suggestion-container")
        flash_notice("Reverted to original description.")
        Success(milestone)
      else
        flash_error("Failed to revert enhancement.")
        failure_result(:update_failed, "Failed to revert enhancement.", errors: milestone.errors)
      end
    rescue ActiveRecord::RecordNotFound
      flash_error("Enhancement not found.")
      failure_result(:not_found, "Enhancement not found.")
    end
  end
end
