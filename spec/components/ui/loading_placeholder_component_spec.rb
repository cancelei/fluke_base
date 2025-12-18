# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::LoadingPlaceholderComponent, type: :component do
  describe "rendering" do
    it "renders a container div" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div")
    end

    it "renders with DaisyUI card and shadow styling" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div.card")
      expect(page).to have_css("div.shadow-xl")
    end

    it "renders with base-100 background" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div.bg-base-100")
    end

    it "renders card with DaisyUI styling" do
      render_inline(described_class.new(title: "Loading", description: "Please wait..."))

      expect(page).to have_css("div.card.bg-base-100.shadow-xl")
    end
  end

  describe "header section" do
    it "renders the title" do
      render_inline(described_class.new(title: "Projects Loading", description: "Fetching data"))

      expect(page).to have_text("Projects Loading")
    end

    it "renders title with DaisyUI card-title class" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("h3.card-title")
    end

    it "renders the description" do
      render_inline(described_class.new(title: "Title", description: "Loading your content"))

      expect(page).to have_text("Loading your content")
    end

    it "renders description with correct styling" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("p.text-sm.opacity-70")
    end

    it "renders header with card-body class" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.card-body")
    end
  end

  describe "loading section" do
    it "renders DaisyUI loading spinner" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("span.loading.loading-spinner")
    end

    it "renders spinner with large size" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("span.loading-lg")
    end

    it "renders spinner with primary color by default" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("span.text-primary")
    end

    it "renders loading element with role and aria-label" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("span[role='status'][aria-label='loading']")
    end

    it "renders loading text" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_text("Loading content...")
    end

    it "renders loading text with correct styling" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("p.mt-3.text-sm.opacity-60")
    end

    it "renders loading section with card-body" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.card-body")
    end

    it "renders loading section with flex centering" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.flex.flex-col.items-center.justify-center")
    end
  end

  describe "accessibility" do
    it "renders spinner with role status" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("span[role='status']")
    end

    it "renders spinner with aria-label" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("span[aria-label='loading']")
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

    it "preserves default card classes with custom class" do
      render_inline(described_class.new(title: "Title", description: "Description", css_class: "my-custom"))

      expect(page).to have_css("div.card.my-custom")
    end
  end
end
