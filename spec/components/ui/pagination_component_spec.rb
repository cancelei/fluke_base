# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::PaginationComponent, type: :component do
  # Create Pagy objects for testing
  let(:multi_page_pagy) { Pagy.new(count: 50, page: 1, items: 10) }
  let(:single_page_pagy) { Pagy.new(count: 5, page: 1, items: 10) }

  describe "render?" do
    it "renders when pagy has multiple pages" do
      component = described_class.new(pagy: multi_page_pagy)

      expect(component.render?).to be true
    end

    it "does not render when pagy has single page" do
      component = described_class.new(pagy: single_page_pagy)

      expect(component.render?).to be false
    end

    it "does not render when pagy is nil" do
      component = described_class.new(pagy: nil)

      expect(component.render?).to be_falsey
    end
  end

  describe "rendering" do
    it "renders a container div" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("div")
    end

    it "renders with glassmorphism styling" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("div.bg-white\\/95")
    end

    it "renders with backdrop blur" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("div.backdrop-blur-md")
    end

    it "renders with shadow" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("div.shadow-lg")
    end

    it "renders with ring border" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("div.ring-1.ring-gray-200\\/50")
    end

    it "renders with rounded corners" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("div.rounded-2xl")
    end

    it "renders with padding" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("div.px-6.py-4")
    end

    it "renders pagination navigation" do
      render_inline(described_class.new(pagy: multi_page_pagy))

      expect(page).to have_css("nav.pagy")
    end
  end

  describe "custom css_class" do
    it "includes custom class when provided" do
      render_inline(described_class.new(pagy: multi_page_pagy, css_class: "custom-class"))

      expect(page).to have_css("div.custom-class")
    end
  end

  describe "remote option" do
    it "accepts remote option" do
      component = described_class.new(pagy: multi_page_pagy, remote: true)

      expect(component.instance_variable_get(:@remote)).to be true
    end

    it "defaults remote to false" do
      component = described_class.new(pagy: multi_page_pagy)

      expect(component.instance_variable_get(:@remote)).to be false
    end
  end
end
