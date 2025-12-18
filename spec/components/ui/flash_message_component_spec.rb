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

    it "renders alert container with DaisyUI classes" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.alert")
      expect(page).to have_css("div[role='alert']")
    end

    it "renders with bottom margin" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.mb-6")
    end

    it "renders icon" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("svg")
    end
  end

  describe "notice type" do
    it "renders with success alert styling" do
      render_inline(described_class.new(type: :notice, message: "Success"))

      expect(page).to have_css("div.alert.alert-success")
    end

    it "renders with stroke-current icon" do
      render_inline(described_class.new(type: :notice, message: "Success"))

      expect(page).to have_css("svg.stroke-current")
    end

    it "renders check icon path" do
      render_inline(described_class.new(type: :notice, message: "Success"))

      expect(page).to have_css("svg path[d*='M9 12l2 2 4-4']")
    end
  end

  describe "alert type" do
    it "renders with error alert styling" do
      render_inline(described_class.new(type: :alert, message: "Error"))

      expect(page).to have_css("div.alert.alert-error")
    end

    it "renders with stroke-current icon" do
      render_inline(described_class.new(type: :alert, message: "Error"))

      expect(page).to have_css("svg.stroke-current")
    end

    it "renders error icon path" do
      render_inline(described_class.new(type: :alert, message: "Error"))

      expect(page).to have_css("svg path")
    end
  end

  describe "success type" do
    it "renders with success alert styling" do
      render_inline(described_class.new(type: :success, message: "Success"))

      expect(page).to have_css("div.alert.alert-success")
    end
  end

  describe "error type" do
    it "renders with error alert styling" do
      render_inline(described_class.new(type: :error, message: "Error"))

      expect(page).to have_css("div.alert.alert-error")
    end
  end

  describe "warning type" do
    it "renders with warning alert styling" do
      render_inline(described_class.new(type: :warning, message: "Warning"))

      expect(page).to have_css("div.alert.alert-warning")
      expect(page).to have_css("svg.stroke-current")
    end
  end

  describe "info type" do
    it "renders with info alert styling" do
      render_inline(described_class.new(type: :info, message: "Info"))

      expect(page).to have_css("div.alert.alert-info")
      expect(page).to have_css("svg.stroke-current")
    end
  end

  describe "unknown type" do
    it "defaults to info styling" do
      render_inline(described_class.new(type: :unknown, message: "Unknown"))

      expect(page).to have_css("div.alert.alert-info")
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
    it "uses DaisyUI alert layout" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.alert")
    end

    it "icon does not shrink" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("svg.shrink-0")
    end

    it "renders message in span" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("span", text: "Test")
    end

    it "icon has correct SVG attributes" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("svg.h-6.w-6")
    end
  end

  describe "type as string" do
    it "handles string type notice" do
      render_inline(described_class.new(type: "notice", message: "Test"))

      expect(page).to have_css("div.alert.alert-success")
    end

    it "handles string type alert" do
      render_inline(described_class.new(type: "alert", message: "Test"))

      expect(page).to have_css("div.alert.alert-error")
    end
  end
end
