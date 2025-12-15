# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::BadgeComponent, type: :component do
  describe "rendering" do
    it "renders text content" do
      render_inline(described_class.new(text: "Active"))

      expect(page).to have_text("Active")
    end

    it "renders as a span element" do
      render_inline(described_class.new(text: "Test"))

      expect(page).to have_css("span")
    end

    it "includes inline-flex base class" do
      render_inline(described_class.new(text: "Test"))

      expect(page).to have_css("span.inline-flex")
    end
  end

  describe "variants" do
    it "renders primary variant by default" do
      render_inline(described_class.new(text: "Primary"))

      expect(page).to have_css("span.bg-indigo-100.text-indigo-800")
    end

    it "renders success variant" do
      render_inline(described_class.new(text: "Success", variant: :success))

      expect(page).to have_css("span.bg-green-100.text-green-800")
    end

    it "renders warning variant" do
      render_inline(described_class.new(text: "Warning", variant: :warning))

      expect(page).to have_css("span.bg-yellow-100.text-yellow-800")
    end

    it "renders danger variant" do
      render_inline(described_class.new(text: "Danger", variant: :danger))

      expect(page).to have_css("span.bg-red-100.text-red-800")
    end

    it "renders secondary variant" do
      render_inline(described_class.new(text: "Secondary", variant: :secondary))

      expect(page).to have_css("span.bg-gray-100.text-gray-800")
    end

    it "renders info variant" do
      render_inline(described_class.new(text: "Info", variant: :info))

      expect(page).to have_css("span.bg-blue-100.text-blue-800")
    end

    it "renders purple variant" do
      render_inline(described_class.new(text: "Purple", variant: :purple))

      expect(page).to have_css("span.bg-purple-100.text-purple-800")
    end
  end

  describe "status mapping" do
    it "maps completed status to success variant" do
      render_inline(described_class.new(text: "Completed", status: :completed))

      expect(page).to have_css("span.bg-green-100.text-green-800")
    end

    it "maps accepted status to success variant" do
      render_inline(described_class.new(text: "Accepted", status: :accepted))

      expect(page).to have_css("span.bg-green-100.text-green-800")
    end

    it "maps pending status to warning variant" do
      render_inline(described_class.new(text: "Pending", status: :pending))

      expect(page).to have_css("span.bg-yellow-100.text-yellow-800")
    end

    it "maps in_progress status to warning variant" do
      render_inline(described_class.new(text: "In Progress", status: :in_progress))

      expect(page).to have_css("span.bg-yellow-100.text-yellow-800")
    end

    it "maps rejected status to danger variant" do
      render_inline(described_class.new(text: "Rejected", status: :rejected))

      expect(page).to have_css("span.bg-red-100.text-red-800")
    end

    it "maps cancelled status to danger variant" do
      render_inline(described_class.new(text: "Cancelled", status: :cancelled))

      expect(page).to have_css("span.bg-red-100.text-red-800")
    end

    it "maps draft status to secondary variant" do
      render_inline(described_class.new(text: "Draft", status: :draft))

      expect(page).to have_css("span.bg-gray-100.text-gray-800")
    end

    it "maps unknown status to info variant" do
      render_inline(described_class.new(text: "Unknown", status: :unknown_status))

      expect(page).to have_css("span.bg-blue-100.text-blue-800")
    end

    it "handles string status values" do
      render_inline(described_class.new(text: "Completed", status: "completed"))

      expect(page).to have_css("span.bg-green-100.text-green-800")
    end
  end

  describe "sizes" do
    it "renders medium size by default" do
      render_inline(described_class.new(text: "Medium"))

      expect(page).to have_css("span.px-2\\.5")
    end

    it "renders small size" do
      render_inline(described_class.new(text: "Small", size: :sm))

      expect(page).to have_css("span.px-2.py-0\\.5.text-xs")
    end

    it "renders large size" do
      render_inline(described_class.new(text: "Large", size: :lg))

      expect(page).to have_css("span.px-3.py-1.text-sm")
    end
  end

  describe "rounded" do
    it "uses rounded-full by default" do
      render_inline(described_class.new(text: "Rounded"))

      expect(page).to have_css("span.rounded-full")
    end

    it "uses regular rounded when specified" do
      render_inline(described_class.new(text: "Rounded", rounded: :normal))

      expect(page).to have_css("span.rounded")
    end
  end

  describe "custom css_class" do
    it "appends custom class" do
      render_inline(described_class.new(text: "Custom", css_class: "my-custom-class"))

      expect(page).to have_css("span.my-custom-class")
    end
  end
end
