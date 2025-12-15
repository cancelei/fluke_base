# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::PageHeaderComponent, type: :component do
  describe "rendering" do
    it "renders a container div" do
      render_inline(described_class.new(title: "Page Title"))

      expect(page).to have_css("div")
    end

    it "renders with default container classes" do
      render_inline(described_class.new(title: "Page Title"))

      expect(page).to have_css("div.max-w-7xl.mx-auto.py-6")
    end

    it "renders with responsive padding" do
      render_inline(described_class.new(title: "Page Title"))

      expect(page).to have_css("div.sm\\:px-6.lg\\:px-8")
    end
  end

  describe "title" do
    it "renders the title text" do
      render_inline(described_class.new(title: "My Projects"))

      expect(page).to have_text("My Projects")
    end

    it "renders title as h1" do
      render_inline(described_class.new(title: "Dashboard"))

      expect(page).to have_css("h1", text: "Dashboard")
    end

    it "renders title with default styling" do
      render_inline(described_class.new(title: "Title"))

      expect(page).to have_css("h1.text-2xl.font-semibold.text-gray-900")
    end
  end

  describe "subtitle" do
    it "renders subtitle when provided" do
      render_inline(described_class.new(title: "Title", subtitle: "Subtitle text"))

      expect(page).to have_text("Subtitle text")
    end

    it "does not render subtitle when not provided" do
      render_inline(described_class.new(title: "Title"))

      expect(page).not_to have_css("p")
    end

    it "renders subtitle with default styling" do
      render_inline(described_class.new(title: "Title", subtitle: "Subtitle"))

      expect(page).to have_css("p.mt-2.text-sm.text-gray-700")
    end
  end

  describe "actions slot" do
    it "renders actions when provided" do
      render_inline(described_class.new(title: "Title")) do |component|
        component.with_actions { "Action Content" }
      end

      expect(page).to have_text("Action Content")
    end

    it "does not render actions container when no actions" do
      result = render_inline(described_class.new(title: "Title"))

      # Only two divs with specific classes - the title section
      title_section = result.css("div.flex-1")
      expect(title_section).to be_present

      # No actions container (class mt-4 sm:mt-0)
      actions_container = result.css("div.mt-4")
      expect(actions_container).not_to be_present
    end

    it "renders actions with default styling" do
      render_inline(described_class.new(title: "Title")) do |component|
        component.with_actions { "Click" }
      end

      expect(page).to have_css("div.mt-4.sm\\:mt-0", text: "Click")
    end
  end

  describe "custom classes" do
    it "uses custom container class" do
      render_inline(described_class.new(title: "Title", container_class: "custom-container"))

      expect(page).to have_css("div.custom-container")
    end

    it "uses custom inner class" do
      render_inline(described_class.new(title: "Title", inner_class: "custom-inner"))

      expect(page).to have_css("div.custom-inner")
    end

    it "uses custom title class" do
      render_inline(described_class.new(title: "Title", title_class: "custom-title"))

      expect(page).to have_css("h1.custom-title")
    end

    it "uses custom subtitle class" do
      render_inline(described_class.new(title: "Title", subtitle: "Sub", subtitle_class: "custom-subtitle"))

      expect(page).to have_css("p.custom-subtitle")
    end

    it "uses custom title section class" do
      render_inline(described_class.new(title: "Title", title_section_class: "custom-section"))

      expect(page).to have_css("div.custom-section")
    end

    it "uses custom actions class" do
      render_inline(described_class.new(title: "Title")) do |component|
        component.with_actions(css_class: "custom-actions") { "Action" }
      end

      expect(page).to have_css("div.custom-actions")
    end
  end

  describe "layout" do
    it "uses flex layout for header row" do
      render_inline(described_class.new(title: "Title"))

      expect(page).to have_css("div.flex.items-center.justify-between")
    end

    it "has margin bottom on header row" do
      render_inline(described_class.new(title: "Title"))

      expect(page).to have_css("div.mb-6")
    end

    it "title section prevents text overflow" do
      render_inline(described_class.new(title: "Title"))

      expect(page).to have_css("div.min-w-0")
    end
  end
end
