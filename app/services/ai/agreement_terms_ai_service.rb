# frozen_string_literal: true

module Ai
  class AgreementTermsAiService
    def initialize(project)
      @agent = Ai::ProjectAgentService.new(project)
    end

    # Returns drafted/refined terms as a String
    def draft_terms(agreement)
      @agent.draft_agreement_terms(agreement)
    end
  end
end
