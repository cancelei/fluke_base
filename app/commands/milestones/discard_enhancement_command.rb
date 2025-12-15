# frozen_string_literal: true

module Milestones
  # Command to discard an AI enhancement suggestion
  # Simply clears the suggestion container without applying changes
  # @return [Dry::Monads::Result] Success(true)
  #
  # Usage in view:
  #   <button data-turbo-command="Milestones::DiscardEnhancementCommand#execute">
  #     Discard
  #   </button>
  class DiscardEnhancementCommand < ApplicationCommand
    def execute
      # Clear any polling state
      delete_page_state(:polling_active)
      delete_page_state(:enhancement_id)

      # Clear the suggestion container
      clear_frame("ai-suggestion-container")

      Success(true)
    end
  end
end
