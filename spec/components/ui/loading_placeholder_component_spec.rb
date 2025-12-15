# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::LoadingPlaceholderComponent, type: :component do
  describe "rendering" do
    it "renders a container div" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div")
    end

    it "renders with shadow and rounded styling" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div.shadow")
      expect(page).to have_css("div.sm\\:rounded-lg")
    end

    it "renders with overflow hidden" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div.overflow-hidden")
    end

    it "renders with white background" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div.bg-white")
    end

    it "renders with top margin" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div.mt-8")
    end
  end

  describe "header section" do
    it "renders the title" do
      render_inline(described_class.new(title: "Projects Loading", description: "Fetching data"))

      expect(page).to have_text("Projects Loading")
    end

    it "renders title with correct styling" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("h3.text-lg.leading-6.font-medium.text-gray-900")
    end

    it "renders the description" do
      render_inline(described_class.new(title: "Title", description: "Loading your content"))

      expect(page).to have_text("Loading your content")
    end

    it "renders description with correct styling" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("p.mt-1.max-w-2xl.text-sm.text-gray-500")
    end

    it "renders header with padding" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.px-4.py-5")
    end
  end

  describe "loading section" do
    it "renders loading spinner" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.animate-spin")
    end

    it "renders spinner with correct size" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.w-6.h-6")
    end

    it "renders spinner with indigo color" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.text-indigo-600")
    end

    it "renders spinner with border styling" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.border-2.border-current.border-t-transparent")
    end

    it "renders spinner with rounded-full" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.rounded-full")
    end

    it "renders loading text" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_text("Loading content...")
    end

    it "renders loading text with correct styling" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("p.mt-2.text-sm.text-gray-500")
    end

    it "renders loading section with border" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.border-t.border-gray-200")
    end

    it "renders loading section centered" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.text-center")
    end
  end

  describe "accessibility" do
    it "renders spinner with role status" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div[role='status']")
    end

    it "renders spinner with aria-label" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div[aria-label='loading']")
    end

    it "renders screen reader text" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("span.sr-only", text: "Loading...")
    end
  end

  describe "custom css_class" do
    it "includes custom class when provided" do
      render_inline(described_class.new(title: "Title", description: "Description", css_class: "custom-class"))

      expect(page).to have_css("div.custom-class")
    end

    it "preserves default classes with custom class" do
      render_inline(described_class.new(title: "Title", description: "Description", css_class: "my-custom"))

      expect(page).to have_css("div.mt-8.my-custom")
    end
  end
end
