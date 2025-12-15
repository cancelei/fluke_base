# frozen_string_literal: true

module Milestones
  # Command to revert form fields to original values (before direct enhancement)
  # Used when the user wants to undo applying a direct enhancement
  # @return [Dry::Monads::Result] Success(original_content) or Failure(error)
  #
  # Usage in view:
  #   <button data-turbo-command="Milestones::RevertDirectEnhancementCommand#execute"
  #           data-original-title="<%= enhancement.original_title %>"
  #           data-original-description="<%= enhancement.original_description %>">
  #     Revert to Original
  #   </button>
  class RevertDirectEnhancementCommand < ApplicationCommand
    def execute
      original_title = element_data(:originalTitle)
      original_description = element_data(:originalDescription)

      if original_description.blank?
        flash_error("No original description available.")
        return failure_result(:missing_data, "No original description available.")
      end

      # Use Turbo Streams to update the form fields with original values
      if original_title.present?
        turbo_streams << turbo_stream.replace(
          "milestone_title",
          "<input type=\"text\" name=\"milestone[title]\" id=\"milestone_title\" " \
          "value=\"#{ERB::Util.html_escape(original_title)}\" class=\"input w-full\">"
        )
      end

      turbo_streams << turbo_stream.replace(
        "milestone_description",
        "<textarea name=\"milestone[description]\" id=\"milestone_description\" " \
        "rows=\"3\" class=\"textarea w-full\">#{ERB::Util.html_escape(original_description)}</textarea>"
      )

      # Clear the suggestion container
      clear_frame("ai-suggestion-container")

      flash_notice("Reverted to original content!")
      Success({ title: original_title, description: original_description })
    end
  end
end
