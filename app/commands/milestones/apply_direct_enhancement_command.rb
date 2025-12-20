# frozen_string_literal: true

module Milestones
  # Command to apply a direct enhancement (not yet saved to DB) to form fields
  # Used when enhancing a new milestone before it's been created
  # @return [Dry::Monads::Result] Success(parsed_content) or Failure(error)
  #
  # Usage in view:
  #   <button data-turbo-command="Milestones::ApplyDirectEnhancementCommand#execute"
  #           data-enhanced-description="<%= enhancement.enhanced_description %>"
  #           data-original-title="<%= enhancement.original_title %>"
  #           data-original-description="<%= enhancement.original_description %>">
  #     Apply to Form
  #   </button>
  class ApplyDirectEnhancementCommand < ApplicationCommand
    def execute
      enhanced_description = element_data(:enhancedDescription)

      if enhanced_description.blank?
        flash_error("No enhanced description available.")
        return failure_result(:missing_data, "No enhanced description available.")
      end

      # Parse the enhanced content to extract title and description
      parsed = parse_enhanced_content(enhanced_description)

      # Use Turbo Streams to update the form fields
      if parsed[:title].present?
        turbo_streams << turbo_stream.replace(
          "milestone_title",
          "<input type=\"text\" name=\"milestone[title]\" id=\"milestone_title\" " \
          "value=\"#{ERB::Util.html_escape(parsed[:title])}\" class=\"input w-full\">"
        )
      end

      turbo_streams << turbo_stream.replace(
        "milestone_description",
        "<textarea name=\"milestone[description]\" id=\"milestone_description\" " \
        "rows=\"3\" class=\"textarea w-full\">#{ERB::Util.html_escape(parsed[:description])}</textarea>"
      )

      # Clear the suggestion container
      clear_frame("ai-suggestion-container")

      flash_notice("Enhanced content applied to form!")
      Success(parsed)
    end

    private

    def parse_enhanced_content(enhanced_text)
      # Look for "Title: [title]" and "Description: [description]" pattern
      title_match = enhanced_text.match(/Title:\s*(.+?)(?:\n|$)/i)
      description_match = enhanced_text.match(/Description:\s*([\s\S]+)/i)

      title = title_match ? title_match[1].strip : nil
      description = description_match ? description_match[1].strip : enhanced_text

      # Clean up the description by removing any remaining "Title: ..." line
      if title_match && !description_match
        description = enhanced_text.sub(/Title:\s*.+?\n/i, "").strip
      end

      { title:, description: }
    end
  end
end
