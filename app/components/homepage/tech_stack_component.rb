# frozen_string_literal: true

module Homepage
  class TechStackComponent < ApplicationComponent
    GITHUB_REPO_URL = "https://github.com/cancelei/fluke_base"

    TECHNOLOGIES = [
      { name: "Ruby on Rails 8", icon: "rails", description: "Backend framework" },
      { name: "Hotwire/Turbo", icon: "hotwire", description: "Real-time updates" },
      { name: "Stimulus", icon: "stimulus", description: "JavaScript sprinkles" },
      { name: "PostgreSQL", icon: "postgresql", description: "Database" },
      { name: "Tailwind CSS", icon: "tailwind", description: "Styling" },
      { name: "DaisyUI", icon: "daisyui", description: "Component library" }
    ].freeze

    def initialize(github_stats: {})
      @github_stats = github_stats
    end

    attr_reader :github_stats

    def technologies
      TECHNOLOGIES
    end

    def stars_count
      github_stats[:stars]
    end

    def forks_count
      github_stats[:forks]
    end

    def github_url
      GITHUB_REPO_URL
    end
  end
end
