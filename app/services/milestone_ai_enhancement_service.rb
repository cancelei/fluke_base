class MilestoneAiEnhancementService
  attr_reader :project, :agent_service

  def initialize(project)
    @project = project
    @agent_service = Ai::ProjectAgentService.new(project)
  end

  def augment_description(title:, description:)
    return "" if title.blank? && description.blank?

    begin
      enhanced_text = agent_service.enhance_milestone(title: title, description: description)
      raise "AI service returned empty response" if enhanced_text.blank?
      enhanced_text
    rescue => e
      Rails.logger.error("AI enhancement failed: #{e.message}")
      raise e
    end
  end


  private

end

