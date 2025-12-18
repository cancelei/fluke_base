# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::EmptyStateComponent, type: :component do
  describe "rendering" do
    it "renders title" do
      render_inline(described_class.new(title: "No items", description: "No items found"))

      expect(page).to have_text("No items")
    end

    it "renders description" do
      render_inline(described_class.new(title: "Empty", description: "Nothing to show here"))

      expect(page).to have_text("Nothing to show here")
    end

    it "renders with centered text" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.text-center")
    end

    it "renders with vertical padding" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.py-12")
    end
  end

  describe "icon" do
    it "renders folder icon by default" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("svg")
    end

    it "renders custom icon" do
      render_inline(described_class.new(title: "Title", description: "Description", icon: :user))

      expect(page).to have_css("svg")
    end

    it "applies icon container styling" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).to have_css("div.mx-auto.h-12.w-12.text-gray-400")
    end
  end

  describe "title styling" do
    it "applies title typography classes" do
      render_inline(described_class.new(title: "My Title", description: "Description"))

      expect(page).to have_css("h3.mt-2.text-sm.font-medium.text-gray-900", text: "My Title")
    end
  end

  describe "description styling" do
    it "applies description typography classes" do
      render_inline(described_class.new(title: "Title", description: "My Description"))

      expect(page).to have_css("p.mt-1.text-sm.text-gray-500", text: "My Description")
    end
  end

  describe "action button" do
    it "does not render action button when action_text is nil" do
      render_inline(described_class.new(title: "Title", description: "Description"))

      expect(page).not_to have_css("a")
    end

    it "does not render action button when action_url is nil" do
      render_inline(described_class.new(
        title: "Title",
        description: "Description",
        action_text: "Add Item"
      ))

      expect(page).not_to have_css("a")
    end

    it "renders action button when both text and url provided" do
      render_inline(described_class.new(
        title: "Title",
        description: "Description",
        action_text: "Add Item",
        action_url: "/items/new"
      ))

      expect(page).to have_css("a[href='/items/new']")
      expect(page).to have_text("Add Item")
    end

    it "renders action button with plus icon by default" do
      render_inline(described_class.new(
        title: "Title",
        description: "Description",
        action_text: "Add",
        action_url: "/add"
      ))

      expect(page).to have_css("a svg")
    end

    it "renders action button with custom icon" do
      render_inline(described_class.new(
        title: "Title",
        description: "Description",
        action_text: "Search",
        action_url: "/search",
        action_icon: :search
      ))

      expect(page).to have_css("a svg")
    end

    it "renders action button with custom variant" do
      render_inline(described_class.new(
        title: "Title",
        description: "Description",
        action_text: "Action",
        action_url: "/action",
        action_variant: :secondary
      ))

      expect(page).to have_css("a.btn.btn-ghost")
    end

    it "wraps action button in div with margin" do
      render_inline(described_class.new(
        title: "Title",
        description: "Description",
        action_text: "Action",
        action_url: "/action"
      ))

      expect(page).to have_css("div.mt-6 a")
    end
  end

  describe "custom css_class" do
    it "appends custom class to container" do
      render_inline(described_class.new(
        title: "Title",
        description: "Description",
        css_class: "my-empty-state"
      ))

      expect(page).to have_css("div.my-empty-state")
    end
  end

  describe "block content" do
    it "renders block content after other elements" do
      render_inline(described_class.new(title: "Title", description: "Description")) do
        "Additional content"
      end

      expect(page).to have_text("Additional content")
    end
  end
end
