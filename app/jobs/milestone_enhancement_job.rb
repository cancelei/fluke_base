class MilestoneEnhancementJob < ApplicationJob
  queue_as :default

  def perform(enhancement_id, title, description)
    enhancement = MilestoneEnhancement.find(enhancement_id)
    start_time = Time.current

    begin
      # Update status to processing
      enhancement.update!(status: "processing")

      # Use the service to get the enhanced description
      service = MilestoneAiEnhancementService.new(enhancement.milestone.project)
      enhanced_description = service.augment_description(
        title:,
        description: description || enhancement.original_description
      )

      processing_time_ms = ((Time.current - start_time) * 1000).to_i

      # Update the enhancement with the result
      enhancement.update!(
        enhanced_description:,
        status: "completed",
        processing_time_ms:,
        context_data: enhancement.context_data.merge({
          processed_at: Time.current.iso8601,
          title_used: title,
          service_used: service.class.name
        })
      )

      # Broadcast the update to the UI
      broadcast_enhancement_update(enhancement)

    rescue => e
      Rails.logger.error("MilestoneEnhancementJob failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      processing_time_ms = ((Time.current - start_time) * 1000).to_i

      # Update status to failed with error details
      enhancement.update!(
        status: "failed",
        processing_time_ms:,
        context_data: enhancement.context_data.merge({
          error_message: e.message,
          failed_at: Time.current.iso8601
        })
      )

      # Broadcast the failure to the UI
      broadcast_enhancement_update(enhancement)
    end
  end

  private

  def broadcast_enhancement_update(enhancement)
    # Use Turbo to update the UI in real-time
    Turbo::StreamsChannel.broadcast_update_to(
      "milestone_#{enhancement.milestone.id}_enhancements",
      target: "ai-suggestion-container",
      partial: "milestones/ai_suggestion",
      locals: { enhancement:, milestone: enhancement.milestone }
    )
  end
end
