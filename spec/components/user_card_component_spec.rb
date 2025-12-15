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

      expect(page).to have_css("a.bg-white\\/80")
      expect(page).to have_css("a.backdrop-blur-sm")
      expect(page).to have_css("a.rounded-2xl")
      expect(page).to have_css("a.shadow-lg")
    end

    it "renders with hover effects" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("a.hover\\:shadow-xl")
      expect(page).to have_css("a.hover\\:-translate-y-1")
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

      expect(page).to have_text("Passionate member of the FlukeBase community")
    end
  end

  describe "avatar section" do
    it "renders avatar section" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("div.bg-gradient-to-br")
    end

    it "uses custom avatar height" do
      render_inline(described_class.new(user: user, avatar_height: "h-32"))

      expect(page).to have_css("div.h-32")
    end

    it "renders default avatar when no image attached" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("svg")
    end
  end

  describe "footer section" do
    it "renders view profile text" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("View Profile")
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

      expect(page).to have_text("project")
    end

    it "hides stats when show_stats is false" do
      render_inline(described_class.new(user: user, show_stats: false))

      # Stats section should not be present
      expect(page).not_to have_css("div.text-xs.text-gray-500.mb-3")
    end
  end

  describe "skills" do
    it "hides skills when show_skills is false" do
      render_inline(described_class.new(user: user, show_skills: false))

      expect(page).not_to have_css("div.flex-wrap.gap-1.mb-3")
    end
  end

  describe "community badge" do
    it "displays community person badge" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("Community Person")
    end
  end
end
