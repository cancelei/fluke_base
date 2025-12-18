# frozen_string_literal: true

module Homepage
  class FeaturesComponent < ApplicationComponent
    FEATURES = [
      {
        title: "Project & Milestone Management",
        description: "Create projects with defined milestones. Track time spent on tasks and visualize progress with optional GitHub integration.",
        icon: "folder",
        capabilities: [
          "Define project stages: Idea, Prototype, Launched, Scaling",
          "Create and track milestones with deadlines",
          "Time tracking tied to specific milestones",
          "GitHub integration for commit tracking",
          "Field-level privacy controls for selective sharing"
        ]
      },
      {
        title: "Collaboration Agreements",
        description: "Document collaborations with structured agreements. Define terms, compensation expectations, and milestone commitments for tracking purposes.",
        icon: "edit",
        capabilities: [
          "Mentorship and co-founder agreement types",
          "Turn-based negotiation with counter-offers",
          "Compensation tracking: hourly, equity, or hybrid",
          "Status tracking through full lifecycle",
          "Direct messaging between participants"
        ]
      }
    ].freeze

    def features
      FEATURES
    end
  end
end
