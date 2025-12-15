# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::FormErrorsComponent, type: :component do
  let(:user) { build(:user) }

  describe "render?" do
    it "does not render when object has no errors" do
      component = described_class.new(object: user)

      expect(component.render?).to be false
    end

    it "renders when object has errors" do
      user.errors.add(:email, "is invalid")
      component = described_class.new(object: user)

      expect(component.render?).to be true
    end

    it "does not render when object is nil" do
      component = described_class.new(object: nil)

      expect(component.render?).to be_falsey
    end
  end

  describe "rendering" do
    before do
      user.errors.add(:email, "is invalid")
      user.errors.add(:password, "is too short")
    end

    it "renders container with error styling" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("div.bg-red-50.border.border-red-200.rounded-md.p-4.mb-6")
    end

    it "renders exclamation-triangle icon" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("svg.text-red-400")
    end

    it "renders error count in header" do
      render_inline(described_class.new(object: user))

      expect(page).to have_text("2 errors prohibited this user from being saved:")
    end

    it "renders singular error message" do
      user.errors.clear
      user.errors.add(:email, "is invalid")

      render_inline(described_class.new(object: user))

      expect(page).to have_text("1 error prohibited this user from being saved:")
    end

    it "renders error messages in list" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("ul.list-disc.pl-5.space-y-1")
      expect(page).to have_css("li", text: "Email is invalid")
      expect(page).to have_css("li", text: "Password is too short")
    end

    it "uses model name in header" do
      render_inline(described_class.new(object: user))

      expect(page).to have_text("this user from being saved")
    end
  end

  describe "styling" do
    before { user.errors.add(:email, "is invalid") }

    it "renders header with correct classes" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("h3.text-sm.font-medium.text-red-800")
    end

    it "renders errors container with correct classes" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("div.mt-2.text-sm.text-red-700")
    end

    it "renders flex layout" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("div.flex")
    end

    it "renders icon container with flex-shrink-0" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("div.flex-shrink-0")
    end

    it "renders content container with left margin" do
      render_inline(described_class.new(object: user))

      expect(page).to have_css("div.ml-3")
    end
  end
end
