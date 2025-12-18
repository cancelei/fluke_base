# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserCardComponent, type: :component do
  let(:user) { build_stubbed(:user, first_name: "John", last_name: "Doe", bio: "Test bio") }
  let(:current_user) { build_stubbed(:user, first_name: "Jane", last_name: "Smith") }

  describe "render?" do
    it "renders when user is present" do
      component = described_class.new(user: user)

      expect(component.render?).to be true
    end

    it "does not render when user is nil" do
      component = described_class.new(user: nil)

      expect(component.render?).to be_falsey
    end
  end

  describe "rendering" do
    it "renders a link element" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("a")
    end

    it "renders with card styling" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("a.bg-base-100")
      expect(page).to have_css("a.border-base-300")
      expect(page).to have_css("a.rounded-xl")
      expect(page).to have_css("a.shadow-sm")
    end

    it "renders with hover effects" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("a.hover\\:shadow-md")
      expect(page).to have_css("a.hover\\:-translate-y-0\\.5")
    end
  end

  describe "user name" do
    it "displays user full name" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("John Doe")
    end

    it "renders name in h3 tag" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("h3", text: "John Doe")
    end
  end

  describe "bio" do
    it "displays user bio when present" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("Test bio")
    end

    it "displays default bio when user bio is blank" do
      user_without_bio = build_stubbed(:user, first_name: "Test", last_name: "User", bio: nil)
      render_inline(described_class.new(user: user_without_bio))

      expect(page).to have_text("Ready to collaborate.")
    end
  end

  describe "avatar section" do
    it "renders avatar component" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("div.avatar")
    end

    it "renders avatar with initials placeholder" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("div.avatar.placeholder")
    end
  end

  describe "compact mode" do
    it "renders compact card when compact is true" do
      render_inline(described_class.new(user: user, compact: true))

      expect(page).to have_css("a.p-3")
    end

    it "hides bio in compact mode" do
      render_inline(described_class.new(user: user, compact: true))

      expect(page).not_to have_text("Test bio")
    end

    it "hides stats in compact mode" do
      render_inline(described_class.new(user: user, compact: true))

      expect(page).not_to have_text("projects")
    end
  end

  describe "footer section" do
    it "renders view text" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("View")
    end
  end

  describe "message button" do
    it "does not render connect button when user is current_user" do
      render_inline(described_class.new(user: user, current_user: user))

      expect(page).not_to have_button("Connect")
    end

    it "does not render connect button when show_message_button is false" do
      render_inline(described_class.new(user: user, current_user: current_user, show_message_button: false))

      expect(page).not_to have_button("Connect")
    end
  end

  describe "stats" do
    it "renders stats section by default" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("projects")
    end

    it "hides stats when show_stats is false" do
      render_inline(described_class.new(user: user, show_stats: false))

      expect(page).not_to have_text("projects")
    end
  end

  describe "skills" do
    it "hides skills when show_skills is false" do
      render_inline(described_class.new(user: user, show_skills: false))

      expect(page).not_to have_css("div.flex-wrap.gap-1.mb-2")
    end
  end

  describe "member badge" do
    it "displays member badge" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("Member")
    end

    it "hides member badge in compact mode" do
      render_inline(described_class.new(user: user, compact: true))

      expect(page).not_to have_css(".badge", text: "Member")
    end
  end
end
