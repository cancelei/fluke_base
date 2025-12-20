# frozen_string_literal: true

module Milestones
  # Command to initiate AI enhancement for milestone description
  # Triggered by enhance button click in milestone form
  # Reads form values via TurboBoost state or params
  # @return [Dry::Monads::Result] Success(enhancement) or Failure(error)
  #
  # Usage in view:
  #   <button data-turbo-command="Milestones::AiEnhanceCommand#execute"
  #           data-project-id="<%= @project.id %>"
  #           data-milestone-id="<%= milestone.id %>">
  #     Enhance with AI
  #   </button>
  class AiEnhanceCommand < ApplicationCommand
    def execute
      # Read form values from params (TurboBoost sends form data)
      title = params[:title].presence || params.dig(:milestone, :title)
      description = params[:description].presence || params.dig(:milestone, :description)
      milestone_id = element_data(:milestoneId).presence
      enhancement_style = params[:enhancement_style].presence || "professional"
      project_id = element_data(:projectId)

      if title.blank? && description.blank?
        flash_error("Please provide a title or description to enhance.")
        return failure_result(:validation_error, "Please provide a title or description to enhance.")
      end

      project = find_project(project_id)

      if milestone_id.present?
        enhance_existing_milestone(project, milestone_id, title, description, enhancement_style)
      else
        enhance_direct(project, title, description, enhancement_style)
      end
    end

    private

    def enhance_existing_milestone(project, milestone_id, title, description, style)
      milestone = project.milestones.find(milestone_id)
      enhancement = milestone.milestone_enhancements.create!(
        user: current_user,
        original_description: description || milestone.description,
        enhancement_style: style,
        status: "processing"
      )

      # Queue background job
      MilestoneEnhancementJob.perform_later(enhancement.id, title, description)

      # Set state for polling (if needed by client)
      set_page_state(:enhancement_id, enhancement.id)
      set_page_state(:polling_active, true)

      update_ai_suggestion(enhancement:, milestone:)
      flash_notice("AI enhancement started. Please wait...")
      Success(enhancement)
    end

    def enhance_direct(project, title, description, style)
      service = MilestoneAiEnhancementService.new(project)
      enhanced_description = service.augment_description(
        title:,
        description:
      )

      # Create a simple enhancement object for the UI (not persisted)
      enhancement = EnhancementResult.new(
        id: nil,
        original_title: title,
        original_description: description,
        enhanced_description:,
        enhancement_style: style,
        status: "completed",
        successful: true,
        direct_enhancement: true,
        created_at: Time.current,
        user: current_user
      )

      milestone = MilestoneStub.new(id: nil)

      update_ai_suggestion(enhancement:, milestone:)
      flash_notice("AI enhancement completed!")
      Success(enhancement)
    rescue StandardError => e
      Rails.logger.error("Direct AI enhancement failed: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      flash_error("AI enhancement failed. Please try again.")
      failure_result(:enhancement_failed, "AI enhancement failed. Please try again.", exception: e.message)
    end
  end
end
