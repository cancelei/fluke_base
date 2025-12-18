# frozen_string_literal: true

module Homepage
  class HowItWorksComponent < ApplicationComponent
    STEPS = [
      {
        number: 1,
        title: "Create Your Profile",
        description: "Set up your profile with skills, experience, and what you're looking to build or contribute to.",
        icon: "user"
      },
      {
        number: 2,
        title: "Start or Join Projects",
        description: "Create your own project with defined milestones or explore existing projects seeking collaborators.",
        icon: "folder"
      },
      {
        number: 3,
        title: "Set Up Agreements",
        description: "Document collaboration terms with structured agreements for tracking compensation and commitments.",
        icon: "edit"
      },
      {
        number: 4,
        title: "Track Progress",
        description: "Log time against milestones, communicate with collaborators, and monitor project advancement.",
        icon: "check"
      }
    ].freeze

    def steps
      STEPS
    end
  end
end
