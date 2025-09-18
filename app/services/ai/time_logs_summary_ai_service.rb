# frozen_string_literal: true

module Ai
  class TimeLogsSummaryAiService
    def initialize(project)
      @agent = Ai::ProjectAgentService.new(project)
    end

    # time_logs: enumerable of TimeLog or hash-like items
    # options: { period_label: "This week", include_breakdown: true }
    def summarize(time_logs, options = {})
      @agent.summarize_time_logs(time_logs, options)
    end
  end
end
