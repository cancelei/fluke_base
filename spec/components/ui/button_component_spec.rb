# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  describe "rendering" do
    it "renders text content" do
      render_inline(described_class.new(text: "Click me"))

      expect(page).to have_text("Click me")
    end

    it "renders as a button element by default" do
      render_inline(described_class.new(text: "Button"))

      expect(page).to have_css("button")
    end

    it "renders base btn class" do
      render_inline(described_class.new(text: "Button"))

      expect(page).to have_css("button.btn")
    end
  end

  describe "as link" do
    it "renders as a link when url is provided" do
      render_inline(described_class.new(text: "Link", url: "/test"))

      expect(page).to have_css("a[href='/test']")
      expect(page).to have_text("Link")
    end

    it "includes method data attribute when specified" do
      render_inline(described_class.new(text: "Delete", url: "/test", method: :delete))

      expect(page).to have_css("a[data-turbo-method='delete']")
    end
  end

  describe "variants" do
    it "renders primary variant by default" do
      render_inline(described_class.new(text: "Primary"))

      expect(page).to have_css("button.btn-primary")
    end

    it "renders secondary variant (maps to btn-ghost)" do
      render_inline(described_class.new(text: "Secondary", variant: :secondary))

      expect(page).to have_css("button.btn-ghost")
    end

    it "renders success variant" do
      render_inline(described_class.new(text: "Success", variant: :success))

      expect(page).to have_css("button.btn-success")
    end

    it "renders danger variant (maps to btn-error)" do
      render_inline(described_class.new(text: "Danger", variant: :danger))

      expect(page).to have_css("button.btn-error")
    end

    it "renders warning variant" do
      render_inline(described_class.new(text: "Warning", variant: :warning))

      expect(page).to have_css("button.btn-warning")
    end

    it "renders ghost variant" do
      render_inline(described_class.new(text: "Ghost", variant: :ghost))

      expect(page).to have_css("button.btn-ghost")
    end
  end

  describe "sizes" do
    it "renders medium size by default (no size class)" do
      render_inline(described_class.new(text: "Medium"))

      expect(page).not_to have_css("button.btn-md")
    end

    it "renders small size" do
      render_inline(described_class.new(text: "Small", size: :sm))

      expect(page).to have_css("button.btn-sm")
    end

    it "renders large size" do
      render_inline(described_class.new(text: "Large", size: :lg))

      expect(page).to have_css("button.btn-lg")
    end
  end

  describe "icons" do
    it "renders icon on the left by default" do
      render_inline(described_class.new(text: "Add", icon: :plus))

      expect(page).to have_css("button svg")
      expect(page).to have_text("Add")
    end

    it "renders icon on the right when specified" do
      render_inline(described_class.new(text: "Next", icon: :chevron_down, icon_position: :right))

      expect(page).to have_css("button svg")
      expect(page).to have_text("Next")
    end
  end

  describe "disabled state" do
    it "renders disabled attribute when disabled" do
      render_inline(described_class.new(text: "Disabled", disabled: true))

      expect(page).to have_css("button[disabled]")
    end
  end

  describe "custom attributes" do
    it "applies custom css_class" do
      render_inline(described_class.new(text: "Custom", css_class: "my-class"))

      expect(page).to have_css("button.my-class")
    end

    it "applies data attributes" do
      render_inline(described_class.new(text: "Data", data: { action: "click->controller#action" }))

      expect(page).to have_css("button[data-action='click->controller#action']")
    end

    it "sets type attribute" do
      render_inline(described_class.new(text: "Submit", type: "submit"))

      expect(page).to have_css("button[type='submit']")
    end
  end

  describe "block content" do
    it "renders block content" do
      render_inline(described_class.new) do
        "Block Content"
      end

      expect(page).to have_text("Block Content")
    end

    it "renders both text and block content" do
      render_inline(described_class.new(text: "Text")) do
        " and Block"
      end

      expect(page).to have_text("Text")
      expect(page).to have_text("and Block")
    end
  end

  describe "loading state" do
    it "renders loading spinner when loading: true" do
      render_inline(described_class.new(text: "Submit", loading: true))

      expect(page).to have_css("button .loading.loading-spinner")
      expect(page).to have_text("Submit")
    end

    it "renders custom loading text" do
      render_inline(described_class.new(text: "Submit", loading: true, loading_text: "Saving..."))

      expect(page).to have_css("button .loading.loading-spinner")
      expect(page).to have_text("Saving...")
    end

    it "disables button when loading" do
      render_inline(described_class.new(text: "Submit", loading: true))

      expect(page).to have_css("button[disabled]")
    end

    it "adds loading classes when loading" do
      render_inline(described_class.new(text: "Submit", loading: true))

      expect(page).to have_css("button.opacity-75.cursor-not-allowed")
    end

    it "adds form-submission-target data attribute when form_submission_target: true" do
      render_inline(described_class.new(text: "Submit", form_submission_target: true))

      expect(page).to have_css("button[data-form-submission-target='submit']")
    end

    it "adds loading_text data attribute when loading_text provided" do
      render_inline(described_class.new(text: "Submit", loading_text: "Processing..."))

      expect(page).to have_css("button[data-loading-text='Processing...']")
    end

    it "accepts disable_with as alias for loading_text" do
      render_inline(described_class.new(text: "Submit", disable_with: "Working..."))

      expect(page).to have_css("button[data-loading-text='Working...']")
    end

    it "uses correct spinner size for xs button" do
      render_inline(described_class.new(text: "Submit", size: :xs, loading: true))

      expect(page).to have_css("button .loading.loading-xs")
    end

    it "uses correct spinner size for lg button" do
      render_inline(described_class.new(text: "Submit", size: :lg, loading: true))

      expect(page).to have_css("button .loading.loading-md")
    end
  end
end
