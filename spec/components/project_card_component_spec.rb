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

      expect(component.render?).to be_falsey
    end
  end

  describe "rendering" do
    it "renders as li element" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("li")
    end

    it "renders with group class for hover effects" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("li.group")
    end

    it "renders card with gradient background" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("div.bg-gradient-to-r")
    end

    it "renders with interactive styling" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("div.hover\\:shadow-lg")
      expect(page).to have_css("div.transition-all")
    end
  end

  describe "project name" do
    it "displays project name as link" do
      render_inline(described_class.new(project:))

      expect(page).to have_link(href: "/projects/#{project.id}")
    end

    it "renders name in h3 with semibold styling" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("h3.font-semibold")
    end
  end

  describe "updated time" do
    it "displays time since update" do
      render_inline(described_class.new(project:))

      expect(page).to have_text(/Updated.*ago/)
    end

    it "renders clock icon" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("svg.h-3.w-3")
    end
  end

  describe "description" do
    it "renders description section" do
      render_inline(described_class.new(project:))

      # Description is rendered with DaisyUI base-content styling
      expect(page).to have_css("p.text-sm.line-clamp-2")
    end

    it "renders description with line clamp styling" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("p.line-clamp-2")
    end
  end

  describe "stats section" do
    it "renders stats with border" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("div.border-t")
    end

    it "displays milestones stat" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("div[title='Project milestones']")
    end

    it "displays agreements stat" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("a[data-tip='View project agreements']")
    end

    it "pluralizes agreement count" do
      render_inline(described_class.new(project:))

      expect(page).to have_text("agreement")
    end
  end

  describe "chevron indicator" do
    it "renders chevron that appears on hover" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("svg.opacity-0.group-hover\\:opacity-100")
    end
  end

  describe "stage badge" do
    it "renders stage badge section" do
      render_inline(described_class.new(project:))

      expect(page).to have_css("div.ml-3.flex.flex-shrink-0")
    end
  end
end
