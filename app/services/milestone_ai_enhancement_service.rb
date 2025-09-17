class MilestoneAiEnhancementService
  attr_reader :project, :agent

  def initialize(project)
    @project = project
    @agent = find_or_create_agent
    validate_configuration!
  end

  def augment_description(title:, description:)
    return "" if title.blank? && description.blank?

    prompt = build_prompt(title, description)

    begin
      chat = create_chat_client
      response = chat.ask(prompt)
      enhanced_text = response.content.strip

      # Validate the response
      if enhanced_text.blank?
        raise "AI service returned empty response"
      end

      enhanced_text
    rescue => e
      Rails.logger.error("AI enhancement failed: #{e.message}")
      raise e
    end
  end


  private

  def find_or_create_agent
    @project.project_agent || @project.create_project_agent!
  end

  def validate_configuration!
    unless @agent.provider.present? && @agent.model.present?
      raise "Project agent configuration is incomplete"
    end

    unless ENV["OPENAI_API_KEY"].present?
      raise "OpenAI API key is not configured"
    end
  end

  def create_chat_client
    case @agent.provider.downcase
    when "openai"
      RubyLLM.chat(model: @agent.model)
    else
      raise "Unsupported AI provider: #{@agent.provider}"
    end
  end

  def build_prompt(title, description)
    project_context = build_project_context

    <<~PROMPT
      You are helping enhance a milestone description for a #{@project.stage} stage project called "#{@project.name}".

      #{project_context}

      Original milestone:
      Title: #{title}
      Description: #{description}

      Please enhance this milestone description to be more detailed, actionable, and professional while keeping the original intent. The enhanced version should include:

      1. Clear, specific objectives
      2. Concrete deliverables and outcomes
      3. Measurable success criteria
      4. Timeline considerations
      5. Any relevant dependencies or prerequisites
      6. Professional language and structure

      Guidelines:
      - Keep the enhanced description focused and actionable
      - Maintain the original scope and intent
      - Use clear, professional language
      - Be specific about what needs to be accomplished
      - Include measurable outcomes where possible

      Return only the enhanced description, without any preamble or explanation.
    PROMPT
  end

  def build_project_context
    context_parts = []

    context_parts << "Project stage: #{@project.stage.humanize}"
    context_parts << "Category: #{@project.category}" if @project.category.present?
    context_parts << "Target market: #{@project.target_market}" if @project.target_market.present?
    context_parts << "Team size: #{@project.team_size}" if @project.team_size.present?

    if context_parts.any?
      "Project context:\n#{context_parts.map { |part| "- #{part}" }.join("\n")}\n"
    else
      ""
    end
  end
end
