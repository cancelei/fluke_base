# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::ToastComponent, type: :component do
  describe "render?" do
    it "renders when message is present" do
      component = described_class.new(type: :success, message: "Hello")

      expect(component.render?).to be true
    end

    it "does not render when message is blank" do
      component = described_class.new(type: :success, message: "")

      expect(component.render?).to be false
    end
  end

  describe "rendering" do
    it "renders with DaisyUI toast positioning" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div.toast")
    end

    it "renders with alert role" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div[role='alert']")
    end

    it "renders alert inside toast container" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div.toast div.alert")
    end

    it "renders with success alert styling" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div.alert.alert-success")
    end
  end

  describe "stimulus data attributes" do
    it "includes toast controller" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div[data-controller='toast']")
    end

    it "includes timeout value" do
      render_inline(described_class.new(type: :success, message: "Test", timeout: 10000))

      expect(page).to have_css("div[data-toast-timeout-value='10000']")
    end

    it "uses default timeout of 5000" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div[data-toast-timeout-value='5000']")
    end
  end

  describe "type normalization" do
    it "normalizes notice to success" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div.alert.alert-success")
    end

    it "normalizes alert to error" do
      render_inline(described_class.new(type: :alert, message: "Test"))

      expect(page).to have_css("div.alert.alert-error")
    end

    it "keeps success as success" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div.alert.alert-success")
    end

    it "keeps error as error" do
      render_inline(described_class.new(type: :error, message: "Test"))

      expect(page).to have_css("div.alert.alert-error")
    end

    it "normalizes unknown types to info" do
      render_inline(described_class.new(type: :unknown, message: "Test"))

      expect(page).to have_css("div.alert.alert-info")
    end

    it "handles string types" do
      render_inline(described_class.new(type: "success", message: "Test"))

      expect(page).to have_css("div.alert.alert-success")
    end
  end

  describe "close button" do
    it "renders close button by default" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("button[data-action='toast#dismiss']")
    end

    it "does not render close button when disabled" do
      render_inline(described_class.new(type: :success, message: "Test", close_button: false))

      expect(page).not_to have_css("button[data-action='toast#dismiss']")
    end
  end
end
