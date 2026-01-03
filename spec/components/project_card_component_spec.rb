# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectCardComponent, type: :component do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:, name: "Test Project", description: "Test description") }

  describe "render?" do
    it "renders when project is present" do
      component = described_class.new(project:)

      expect(component.render?).to be true
    end

    it "does not render when project is nil" do
      component = described_class.new(project: nil)

      expect(component.render?).to be false
    end
  end

  describe "rendering content" do
    it "renders project name" do
      render_inline(described_class.new(project:, current_user: user))

      expect(rendered_content).to include("Test Project")
    end

    it "renders project description" do
      render_inline(described_class.new(project:, current_user: user))

      expect(rendered_content).to include("Test description")
    end

    it "renders project stage badge" do
      render_inline(described_class.new(project:, current_user: user))

      expect(rendered_content).to include(project.stage.humanize)
    end
  end

  describe "variants" do
    it "renders grid variant by default" do
      render_inline(described_class.new(project:, current_user: user))

      expect(rendered_content).to include("View Details")
    end

    it "renders list variant" do
      render_inline(described_class.new(project:, current_user: user, variant: :list))

      expect(rendered_content).to include("interactive-card")
    end

    it "renders compact variant" do
      render_inline(described_class.new(project:, current_user: user, variant: :compact))

      expect(rendered_content).to include("card-compact")
    end
  end
end
