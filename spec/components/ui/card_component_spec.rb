# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::CardComponent, type: :component do
  describe "rendering" do
    it "renders content" do
      render_inline(described_class.new) do
        "Card content"
      end

      expect(page).to have_text("Card content")
    end

    it "renders as a div element" do
      render_inline(described_class.new) { "Content" }

      expect(page).to have_css("div")
    end
  end

  describe "variants" do
    it "renders default variant with glassmorphism styling" do
      render_inline(described_class.new) { "Content" }

      expect(page).to have_css("div.bg-white\\/95")
      expect(page).to have_css("div.backdrop-blur-md")
      expect(page).to have_css("div.shadow-xl")
      expect(page).to have_css("div.rounded-2xl")
    end

    it "renders simple variant" do
      render_inline(described_class.new(variant: :simple)) { "Content" }

      expect(page).to have_css("div.bg-white")
      expect(page).to have_css("div.shadow-lg")
      expect(page).to have_css("div.rounded-xl")
    end

    it "renders minimal variant" do
      render_inline(described_class.new(variant: :minimal)) { "Content" }

      expect(page).to have_css("div.shadow-md")
    end

    it "renders gradient variant" do
      render_inline(described_class.new(variant: :gradient)) { "Content" }

      expect(page).to have_css("div.bg-gradient-to-br")
    end

    it "renders elevated variant" do
      render_inline(described_class.new(variant: :elevated)) { "Content" }

      expect(page).to have_css("div.shadow-2xl")
    end

    it "renders interactive variant" do
      render_inline(described_class.new(variant: :interactive)) { "Content" }

      expect(page).to have_css("div.cursor-pointer")
    end

    it "renders flat variant" do
      render_inline(described_class.new(variant: :flat)) { "Content" }

      expect(page).to have_css("div.border-gray-200")
    end
  end

  describe "padding" do
    it "applies padding by default" do
      render_inline(described_class.new) { "Content" }

      expect(page).to have_css("div div.px-6.py-6")
    end

    it "removes padding when disabled" do
      render_inline(described_class.new(padding: false)) { "Content" }

      expect(page).not_to have_css("div.px-6")
    end
  end

  describe "header slot" do
    it "renders header with title" do
      render_inline(described_class.new) do |card|
        card.with_header(title: "Card Title")
        "Content"
      end

      expect(page).to have_text("Card Title")
      expect(page).to have_css("h3.text-lg.font-medium")
    end

    it "renders header with subtitle" do
      render_inline(described_class.new) do |card|
        card.with_header(title: "Title", subtitle: "Subtitle text")
        "Content"
      end

      expect(page).to have_text("Title")
      expect(page).to have_text("Subtitle text")
    end

    it "renders header with custom content" do
      render_inline(described_class.new) do |card|
        card.with_header { "Custom header content" }
        "Content"
      end

      expect(page).to have_text("Custom header content")
    end

    it "applies header styling" do
      render_inline(described_class.new) do |card|
        card.with_header(title: "Title")
        "Content"
      end

      expect(page).to have_css("div.border-b.border-gray-100\\/50")
    end
  end

  describe "footer slot" do
    it "renders footer content" do
      render_inline(described_class.new) do |card|
        card.with_footer { "Footer content" }
        "Content"
      end

      expect(page).to have_text("Footer content")
    end

    it "applies footer styling" do
      render_inline(described_class.new) do |card|
        card.with_footer { "Footer" }
        "Content"
      end

      expect(page).to have_css("div.border-t.border-gray-100\\/50")
    end

    it "applies custom css class to footer" do
      render_inline(described_class.new) do |card|
        card.with_footer(css_class: "custom-footer") { "Footer" }
        "Content"
      end

      expect(page).to have_css("div.custom-footer")
    end
  end

  describe "section slots" do
    it "renders multiple sections" do
      render_inline(described_class.new) do |card|
        card.with_section { "Section 1" }
        card.with_section { "Section 2" }
        "Content"
      end

      expect(page).to have_text("Section 1")
      expect(page).to have_text("Section 2")
    end

    it "renders section with title" do
      render_inline(described_class.new) do |card|
        card.with_section(title: "Section Title") { "Section content" }
        "Content"
      end

      expect(page).to have_text("Section Title")
      expect(page).to have_css("h4.text-sm.font-medium")
    end

    it "applies section styling" do
      render_inline(described_class.new) do |card|
        card.with_section { "Section" }
        "Content"
      end

      expect(page).to have_css("div.border-t.border-gray-100")
    end
  end

  describe "custom css_class" do
    it "appends custom class" do
      render_inline(described_class.new(css_class: "my-custom-card")) { "Content" }

      expect(page).to have_css("div.my-custom-card")
    end
  end

  describe "additional options" do
    it "passes through data attributes" do
      render_inline(described_class.new(data: { controller: "card" })) { "Content" }

      expect(page).to have_css("div[data-controller='card']")
    end

    it "passes through id attribute" do
      render_inline(described_class.new(id: "my-card")) { "Content" }

      expect(page).to have_css("div#my-card")
    end
  end
end
