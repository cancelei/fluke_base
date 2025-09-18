# frozen_string_literal: true

module Ai
  class ProjectAgentService
    attr_reader :project, :agent

    def initialize(project)
      @project = project
      @agent = project.project_agent || project.create_project_agent!
      Ai::OpenaiAssistantProvisioningService.new(project).provision! if project.project_agent.openai_assistant_id.blank?
    end

    # Generic chat entry-point for all AI interactions in the project
    #
    # Params:
    # - prompt: String user prompt
    # - system: Optional system message/context
    # - model: Optional model override
    # Returns: String content
    def chat(prompt:, system: nil, model: nil)
      validate_configuration!

      if use_openai_assistant?
        return chat_via_openai_assistant(prompt: prompt, system: system)
      end

      chat = create_chat_client(model)
      composed = [system, prompt].compact.join("\n\n")
      response = chat.ask(composed)

      content = response.respond_to?(:content) ? response.content.to_s : response.to_s
      content.strip
    rescue => e
      Rails.logger.error("[AI][ProjectAgentService] Chat failed for project ##{project.id}: #{e.class} - #{e.message}")
      raise
    end

    # Opinionated helper for milestone enhancement specifically
    def enhance_milestone(title:, description:)
      return "" if title.blank? && description.blank?

      chat(
        prompt: build_milestone_prompt(title, description),
        system: default_system_instructions
      )
    end

    # Draft agreement terms or improve existing ones using project context
    # agreement: Agreement (expects fields like agreement_type, payment_type, weekly_hours, tasks, terms)
    def draft_agreement_terms(agreement)
      prompt = build_agreement_prompt(agreement)
      chat(prompt: prompt, system: default_system_instructions)
    end

    # Summarize time logs for a given period (expects an enumerable of TimeLog or hash-like items)
    # options: { period_label: "This week", include_breakdown: true }
    def summarize_time_logs(time_logs, options = {})
      prompt = build_time_logs_prompt(time_logs, options)
      chat(prompt: prompt, system: default_system_instructions)
    end

    # Summarize GitHub activity for a branch or overall
    def summarize_github_activity(branch: nil, entries: nil)
      prompt = build_github_activity_prompt(branch: branch, entries: entries)
      chat(prompt: prompt, system: default_system_instructions)
    end

    private

    def validate_configuration!
      raise "Project agent configuration is incomplete" unless agent.provider.present? && agent.model.present?

      case agent.provider.downcase
      when "openai"
        raise "OpenAI API key is not configured" unless ENV["OPENAI_API_KEY"].present?
      when "anthropic"
        raise "Anthropic API key is not configured" unless ENV["ANTHROPIC_API_KEY"].present?
      else
        raise "Unsupported AI provider: #{agent.provider}"
      end
    end

    def create_chat_client(model_override = nil)
      model_to_use = model_override.presence || agent.model

      case agent.provider.downcase
      when "openai"
        RubyLLM.chat(model: model_to_use)
      when "anthropic"
        RubyLLM.chat(provider: :anthropic, model: model_to_use)
      else
        raise "Unsupported AI provider: #{agent.provider}"
      end
    end

    # --- OpenAI Assistants API v2 flow ---
    def use_openai_assistant?
      agent.provider.to_s.downcase == "openai" && agent.respond_to?(:openai_assistant_id) && agent.openai_assistant_id.present?
    end

    def chat_via_openai_assistant(prompt:, system: nil)
      thread_id = openai_create_thread
      openai_add_message(thread_id, prompt)
      run_id = openai_create_run(thread_id, agent.openai_assistant_id, system)
      openai_wait_run(thread_id, run_id)
      openai_last_assistant_message(thread_id)
    end

    def openai_create_thread
      resp = HTTParty.post(
        "https://api.openai.com/v1/threads",
        headers: openai_headers,
        body: {}.to_json
      )
      body = json_body(resp)
      id = body["id"].to_s
      raise "Failed to create thread: #{resp.code} - #{resp.body}" if id.blank?
      id
    end

    def openai_add_message(thread_id, content)
      resp = HTTParty.post(
        "https://api.openai.com/v1/threads/#{thread_id}/messages",
        headers: openai_headers,
        body: { role: "user", content: content.to_s }.to_json
      )
      raise "Failed to add message: #{resp.code} - #{resp.body}" unless resp.code.between?(200, 299)
    end

    def openai_create_run(thread_id, assistant_id, system)
      payload = { assistant_id: assistant_id }
      payload[:instructions] = system if system.present?

      resp = HTTParty.post(
        "https://api.openai.com/v1/threads/#{thread_id}/runs",
        headers: openai_headers,
        body: payload.to_json
      )
      body = json_body(resp)
      id = body["id"].to_s
      raise "Failed to create run: #{resp.code} - #{resp.body}" if id.blank?
      id
    end

    def openai_wait_run(thread_id, run_id)
      60.times do
        resp = HTTParty.get(
          "https://api.openai.com/v1/threads/#{thread_id}/runs/#{run_id}",
          headers: openai_headers
        )
        body = json_body(resp)
        status = body["status"].to_s
        case status
        when "completed"
          return
        when "failed", "cancelled", "expired"
          raise "Run #{status}: #{body}"
        end
        sleep 0.5
      end
      raise "Run did not complete in time"
    end

    def openai_last_assistant_message(thread_id)
      resp = HTTParty.get(
        "https://api.openai.com/v1/threads/#{thread_id}/messages?limit=10",
        headers: openai_headers
      )
      body = json_body(resp)
      data = Array(body["data"]) # newest first per OpenAI spec
      msg = data.find { |m| m["role"] == "assistant" }
      return "" unless msg
      parts = Array(msg["content"]).map { |c| c["text"] && c["text"]["value"] }.compact
      parts.join("\n").strip
    end

    def openai_headers
      {
        "Authorization" => "Bearer #{ENV["OPENAI_API_KEY"]}",
        "Content-Type" => "application/json",
        "OpenAI-Beta" => "assistants=v2"
      }
    end

    def json_body(resp)
      JSON.parse(resp.body)
    rescue JSON::ParserError
      {}
    end

    def default_system_instructions
      <<~SYS
        You are FlukeBase Project AI Agent. You assist with project management, milestone drafting, agreement support, and developer productivity.
        Respond concisely, professionally, and with actionable structure.
      SYS
    end

    def build_milestone_prompt(title, description)
      project_context = build_project_context

      <<~PROMPT
        You are enhancing a milestone for the project "#{project.name}" (#{project.stage}).

        #{project_context}

        Original milestone:
        Title: #{title}
        Description: #{description}

        Please enhance this milestone description so it is more detailed, actionable, and professional while keeping intent intact. The enhanced version must include:
        1) Clear, specific objectives
        2) Concrete deliverables and outcomes
        3) Measurable success criteria
        4) Timeline considerations
        5) Dependencies or prerequisites
        6) Professional language and structure

        Return only the enhanced description, no preamble.
      PROMPT
    end

    def build_project_context
      parts = []
      parts << "Project stage: #{project.stage.to_s.humanize}" if project.stage.present?
      parts << "Category: #{project.category}" if project.respond_to?(:category) && project.category.present?
      parts << "Target market: #{project.target_market}" if project.respond_to?(:target_market) && project.target_market.present?
      parts << "Team size: #{project.team_size}" if project.respond_to?(:team_size) && project.team_size.present?

      return "" if parts.empty?

      "Project context:\n" + parts.map { |p| "- #{p}" }.join("\n") + "\n"
    end

    def build_agreement_prompt(agreement)
      project_context = build_project_context
      details = []
      details << "Agreement type: #{agreement.agreement_type}" if agreement.respond_to?(:agreement_type) && agreement.agreement_type.present?
      details << "Payment type: #{agreement.payment_type}" if agreement.respond_to?(:payment_type) && agreement.payment_type.present?
      details << "Weekly hours: #{agreement.weekly_hours}" if agreement.respond_to?(:weekly_hours) && agreement.weekly_hours.present?
      details << "Equity %: #{agreement.equity_percentage}" if agreement.respond_to?(:equity_percentage) && agreement.equity_percentage.present?
      details << "Hourly rate: #{agreement.hourly_rate}" if agreement.respond_to?(:hourly_rate) && agreement.hourly_rate.present?
      details << "Tasks: #{Array(agreement.tasks).join(", ")}" if agreement.respond_to?(:tasks) && agreement.tasks.present?
      existing_terms = agreement.respond_to?(:terms) ? agreement.terms.to_s : ""

      <<~PROMPT
        Draft or refine the agreement terms for the project "#{project.name}".

        #{project_context}

        Agreement context:
        #{details.map { |d| "- #{d}" }.join("\n")}

        Existing terms (if any):
        #{existing_terms}

        Please produce clear, professional, structured agreement terms covering scope, responsibilities, deliverables, communication cadence, confidentiality, IP, timelines, acceptance criteria, and payment terms, consistent with the context above. Return terms only.
      PROMPT
    end

    def build_time_logs_prompt(time_logs, options)
      period = options[:period_label] || "Selected period"
      include_breakdown = options.fetch(:include_breakdown, true)

      rows = Array(time_logs).map do |t|
        # Expect either model or hash-like
        title = (t.respond_to?(:title) ? t.title : t[:title]) rescue nil
        duration = (t.respond_to?(:duration) ? t.duration : t[:duration]) rescue nil
        date = (t.respond_to?(:date) ? t.date : t[:date]) rescue nil
        milestone = (t.respond_to?(:milestone) ? t.milestone&.title : t[:milestone]) rescue nil
        "- #{date}: #{title} (#{duration}h)#{milestone ? " [#{milestone}]" : ""}"
      end

      project_context = build_project_context

      <<~PROMPT
        Provide a concise, actionable summary of the time logged for the project "#{project.name}" during: #{period}.

        #{project_context}

        Time log entries:
        #{rows.join("\n")}

        Please include key accomplishments, any blockers, and suggested next steps.#{include_breakdown ? " Provide a brief breakdown by milestone if relevant." : ""}
        Return a short, professional summary.
      PROMPT
    end

    def build_github_activity_prompt(branch:, entries:)
      project_context = build_project_context
      header = branch.present? ? " for branch '#{branch}'" : ""

      rows = Array(entries).map do |e|
        msg = (e.respond_to?(:message) ? e.message : e[:message]) rescue nil
        author = (e.respond_to?(:author) ? e.author : e[:author]) rescue nil
        date = (e.respond_to?(:commit_date) ? e.commit_date : (e[:date] || e[:commit_date])) rescue nil
        added = (e.respond_to?(:lines_added) ? e.lines_added : e[:lines_added]) rescue nil
        removed = (e.respond_to?(:lines_removed) ? e.lines_removed : e[:lines_removed]) rescue nil
        "- #{date}: #{msg} (#{author}, +#{added}/-#{removed})"
      end

      <<~PROMPT
        Summarize recent GitHub activity#{header} for the project "#{project.name}". Focus on themes of work, areas of impact, and potential follow-ups.

        #{project_context}

        Commits:
        #{rows.join("\n")}

        Provide a concise summary and recommended next steps.
      PROMPT
    end
  end
end
