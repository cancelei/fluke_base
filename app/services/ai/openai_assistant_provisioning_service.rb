# frozen_string_literal: true

module Ai
  # Creates/updates an OpenAI Assistant for a given project so it appears in the OpenAI Dashboard.
  # Stores the resulting Assistant ID on ProjectAgent#openai_assistant_id.
  # Requires: ENV["OPENAI_API_KEY"] and ProjectAgent with provider: "openai".
  class OpenaiAssistantProvisioningService
    OPENAI_ASSISTANTS_ENDPOINT = "https://api.openai.com/v1/assistants".freeze

    def initialize(project)
      @project = project
      @agent = project.project_agent || project.create_project_agent!
      validate!
    end

    # Creates a new assistant if none exists, otherwise returns existing id unless force is true.
    # Returns the assistant id as a string.
    def provision!(force: false)
      return @agent.openai_assistant_id if @agent.openai_assistant_id.present? && !force

      payload = build_payload
      response = http_post(OPENAI_ASSISTANTS_ENDPOINT, payload)

      unless response.code.to_i.between?(200, 299)
        raise "OpenAI Assistants API error: #{response.code} - #{response.body}"
      end

      body = parse_json(response.body)
      id = body["id"].to_s
      raise "Assistant creation failed: missing id" if id.blank?

      @agent.update!(openai_assistant_id: id)
      id
    end

    private

    def validate!
      raise "OpenAI API key is not configured" if ENV["OPENAI_API_KEY"].to_s.strip.empty?
      raise "Project agent provider must be 'openai'" unless @agent.provider.to_s.downcase == "openai"
      raise "Project agent model is required" if @agent.model.to_s.strip.empty?
    end

    def build_payload
      name = "FlukeBase Agent — #{truncate(@project.name, 40)}"
      instructions = default_system_instructions + "\n\n" + project_context

      {
        name: name,
        model: @agent.model,
        instructions: instructions
        # You can attach tools, file_search, code_interpreter, etc., here if needed
        # tools: [ { type: "file_search" } ]
      }
    end

    def http_post(url, payload)
      HTTParty.post(
        url,
        headers: {
          "Authorization" => "Bearer #{ENV["OPENAI_API_KEY"]}",
          "Content-Type" => "application/json",
          # Required by OpenAI to access Assistants API v2
          "OpenAI-Beta" => "assistants=v2"
        },
        body: JSON.dump(payload)
      )
    end

    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end

    def truncate(text, length)
      text.to_s.length > length ? text.to_s[0...length] + "…" : text.to_s
    end

    def default_system_instructions
      <<~SYS
        You are FlukeBase Project AI Agent. You assist with project management, milestone drafting, agreement support, and developer productivity.
        Respond concisely, professionally, and with actionable structure.
      SYS
    end

    def project_context
      parts = []
      parts << "Project stage: #{@project.stage.to_s.humanize}" if @project.stage.present?
      parts << "Category: #{@project.category}" if @project.respond_to?(:category) && @project.category.present?
      parts << "Target market: #{@project.target_market}" if @project.respond_to?(:target_market) && @project.target_market.present?
      parts << "Team size: #{@project.team_size}" if @project.respond_to?(:team_size) && @project.team_size.present?

      return "" if parts.empty?

      "Project context:\n" + parts.map { |p| "- #{p}" }.join("\n") + "\n"
    end
  end
end
