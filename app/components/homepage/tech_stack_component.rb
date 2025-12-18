# frozen_string_literal: true

module Homepage
  class TechStackComponent < ApplicationComponent
    TECHNOLOGIES = [
      { name: "Ruby on Rails 8", icon: "rails", description: "Backend framework" },
      { name: "Hotwire/Turbo", icon: "hotwire", description: "Real-time updates" },
      { name: "Stimulus", icon: "stimulus", description: "JavaScript sprinkles" },
      { name: "PostgreSQL", icon: "postgresql", description: "Database" },
      { name: "Tailwind CSS", icon: "tailwind", description: "Styling" },
      { name: "DaisyUI", icon: "daisyui", description: "Component library" }
    ].freeze

    def technologies
      TECHNOLOGIES
    end
  end
end
