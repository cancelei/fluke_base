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
    it "renders a div with toast-notification class" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div.toast-notification")
    end

    it "renders with alert role" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div[role='alert']")
    end

    it "renders with aria-live polite" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div[aria-live='polite']")
    end

    it "renders with aria-atomic true" do
      render_inline(described_class.new(type: :success, message: "Success!"))

      expect(page).to have_css("div[aria-atomic='true']")
    end
  end

  describe "stimulus data attributes" do
    it "includes toast controller" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div[data-controller='toast']")
    end

    it "includes type value" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div[data-toast-type-value='success']")
    end

    it "includes message value" do
      render_inline(described_class.new(type: :success, message: "Test message"))

      expect(page).to have_css("div[data-toast-message-value='Test message']")
    end

    it "includes timeout value" do
      render_inline(described_class.new(type: :success, message: "Test", timeout: 10000))

      expect(page).to have_css("div[data-toast-timeout-value='10000']")
    end

    it "uses default timeout of 5000" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div[data-toast-timeout-value='5000']")
    end

    it "includes close button value" do
      render_inline(described_class.new(type: :success, message: "Test", close_button: false))

      expect(page).to have_css("div[data-toast-close-button-value='false']")
    end

    it "includes progress bar value" do
      render_inline(described_class.new(type: :success, message: "Test", progress_bar: false))

      expect(page).to have_css("div[data-toast-progress-bar-value='false']")
    end

    it "includes position class value" do
      render_inline(described_class.new(type: :success, message: "Test", position: "toast-bottom-left"))

      expect(page).to have_css("div[data-toast-position-class-value='toast-bottom-left']")
    end

    it "includes title when provided" do
      render_inline(described_class.new(type: :success, message: "Test", title: "Success Title"))

      expect(page).to have_css("div[data-toast-title-value='Success Title']")
    end

    it "includes unique toast id" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div[data-toast-id]")
    end
  end

  describe "type normalization" do
    it "normalizes notice to success" do
      render_inline(described_class.new(type: :notice, message: "Test"))

      expect(page).to have_css("div[data-toast-type-value='success']")
    end

    it "normalizes alert to error" do
      render_inline(described_class.new(type: :alert, message: "Test"))

      expect(page).to have_css("div[data-toast-type-value='error']")
    end

    it "keeps success as success" do
      render_inline(described_class.new(type: :success, message: "Test"))

      expect(page).to have_css("div[data-toast-type-value='success']")
    end

    it "keeps error as error" do
      render_inline(described_class.new(type: :error, message: "Test"))

      expect(page).to have_css("div[data-toast-type-value='error']")
    end

    it "normalizes unknown types to info" do
      render_inline(described_class.new(type: :unknown, message: "Test"))

      expect(page).to have_css("div[data-toast-type-value='info']")
    end

    it "handles string types" do
      render_inline(described_class.new(type: "success", message: "Test"))

      expect(page).to have_css("div[data-toast-type-value='success']")
    end
  end

  describe "actions" do
    it "includes actions as JSON when provided" do
      actions = [ { label: "View", url: "/test" } ]
      result = render_inline(described_class.new(type: :success, message: "Test", actions: actions))

      expect(result.to_html).to include("data-toast-actions-value")
    end

    it "does not include actions when empty" do
      result = render_inline(described_class.new(type: :success, message: "Test"))

      expect(result.to_html).not_to include("data-toast-actions-value")
    end
  end
end
