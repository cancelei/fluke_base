# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::FlashMessageComponent, type: :component do
  describe "render?" do
    it "renders when message is present" do
      component = described_class.new(type: :notice, message: "Hello")

      expect(component.render?).to be true
    end

    it "does not render when message is blank" do
      component = described_class.new(type: :notice, message: "")

      expect(component.render?).to be false
    end

    it "does not render when message is nil" do
      component = described_class.new(type: :notice, message: nil)

      expect(component.render?).to be false
    end
  end

  describe "rendering" do
    it "renders message text" do
      render_inline(described_class.new(type: :notice, message: "Operation successful"))

      expect(page).to have_text("Operation successful")
    end

    it "renders container with rounded corners" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.rounded-md")
    end

    it "renders with padding" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.p-4.mb-6")
    end

    it "renders icon" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("svg")
    end
  end

  describe "notice type" do
    it "renders with green background" do
      render_inline(described_class.new(type: :notice, message: "Success"))

      expect(page).to have_css("div.bg-green-50")
    end

    it "renders with green text" do
      render_inline(described_class.new(type: :notice, message: "Success"))

      expect(page).to have_css("p.text-green-800")
    end

    it "renders check icon" do
      render_inline(described_class.new(type: :notice, message: "Success"))

      expect(page).to have_css("svg.text-green-400")
    end
  end

  describe "alert type" do
    it "renders with red background" do
      render_inline(described_class.new(type: :alert, message: "Error"))

      expect(page).to have_css("div.bg-red-50")
    end

    it "renders with red text" do
      render_inline(described_class.new(type: :alert, message: "Error"))

      expect(page).to have_css("p.text-red-800")
    end

    it "renders with red icon" do
      render_inline(described_class.new(type: :alert, message: "Error"))

      expect(page).to have_css("svg.text-red-400")
    end
  end

  describe "success type" do
    it "renders with green styling" do
      render_inline(described_class.new(type: :success, message: "Success"))

      expect(page).to have_css("div.bg-green-50")
      expect(page).to have_css("p.text-green-800")
    end
  end

  describe "error type" do
    it "renders with red styling" do
      render_inline(described_class.new(type: :error, message: "Error"))

      expect(page).to have_css("div.bg-red-50")
      expect(page).to have_css("p.text-red-800")
    end
  end

  describe "warning type" do
    it "renders with yellow styling" do
      render_inline(described_class.new(type: :warning, message: "Warning"))

      expect(page).to have_css("div.bg-yellow-50")
      expect(page).to have_css("p.text-yellow-800")
      expect(page).to have_css("svg.text-yellow-400")
    end
  end

  describe "info type" do
    it "renders with blue styling" do
      render_inline(described_class.new(type: :info, message: "Info"))

      expect(page).to have_css("div.bg-blue-50")
      expect(page).to have_css("p.text-blue-800")
      expect(page).to have_css("svg.text-blue-400")
    end
  end

  describe "unknown type" do
    it "defaults to info styling" do
      render_inline(described_class.new(type: :unknown, message: "Unknown"))

      expect(page).to have_css("div.bg-blue-50")
    end
  end

  describe "message sanitization" do
    it "escapes plain text messages" do
      render_inline(described_class.new(type: :notice, message: "<script>alert('xss')</script>"))

      expect(page).not_to have_css("script")
      expect(page).to have_text("<script>alert('xss')</script>")
    end

    it "allows anchor tags in messages" do
      render_inline(described_class.new(type: :notice, message: 'Click <a href="/test">here</a>'))

      expect(page).to have_css("a[href='/test']")
      expect(page).to have_text("here")
    end

    it "strips disallowed tags from anchor messages" do
      render_inline(described_class.new(type: :notice, message: '<a href="/test">Link</a><script>bad</script>'))

      expect(page).to have_css("a")
      expect(page).not_to have_css("script")
    end
  end

  describe "layout" do
    it "uses flex layout" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.flex")
    end

    it "icon container does not shrink" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.flex-shrink-0")
    end

    it "message has left margin" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.ml-3")
    end

    it "message text has correct styling" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("p.text-sm.font-medium")
    end
  end

  describe "type as string" do
    it "handles string type notice" do
      render_inline(described_class.new(type: "notice", message: "Test"))

      expect(page).to have_css("div.bg-green-50")
    end

    it "handles string type alert" do
      render_inline(described_class.new(type: "alert", message: "Test"))

      expect(page).to have_css("div.bg-red-50")
    end
  end
end
