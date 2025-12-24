# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::AvatarGroupComponent, type: :component do
  let(:users) { create_list(:user, 5) }

  describe "rendering" do
    it "does not render when users array is empty" do
      render_inline(described_class.new(users: []))

      expect(page).not_to have_css(".avatar-group")
    end

    it "does not render when users is nil" do
      render_inline(described_class.new(users: nil))

      expect(page).not_to have_css(".avatar-group")
    end

    it "renders avatar-group container" do
      render_inline(described_class.new(users: users.take(2)))

      expect(page).to have_css(".avatar-group")
    end

    it "includes Stimulus controller" do
      render_inline(described_class.new(users: users.take(2)))

      expect(page).to have_css('[data-controller="avatar-group"]')
    end
  end

  describe "visible users" do
    it "displays up to max_visible avatars by default (3)" do
      render_inline(described_class.new(users:))

      expect(page).to have_css('[data-avatar-group-target="avatarWrapper"]', count: 3)
    end

    it "respects custom max_visible setting" do
      render_inline(described_class.new(users:, max_visible: 4))

      expect(page).to have_css('[data-avatar-group-target="avatarWrapper"]', count: 4)
    end

    it "shows all users when fewer than max_visible" do
      render_inline(described_class.new(users: users.take(2), max_visible: 3))

      expect(page).to have_css('[data-avatar-group-target="avatarWrapper"]', count: 2)
    end
  end

  describe "overflow badge" do
    it "shows overflow badge when users exceed max_visible" do
      render_inline(described_class.new(users:, max_visible: 3))

      expect(page).to have_text("+2")
    end

    it "does not show overflow badge when users equal max_visible" do
      render_inline(described_class.new(users: users.take(3), max_visible: 3))

      expect(page).not_to have_css(".dropdown")
    end

    it "shows correct overflow count" do
      users_list = create_list(:user, 10)
      render_inline(described_class.new(users: users_list, max_visible: 3))

      expect(page).to have_text("+7")
    end

    it "includes dropdown for overflow" do
      render_inline(described_class.new(users:, max_visible: 3))

      expect(page).to have_css(".dropdown.dropdown-hover")
    end
  end

  describe "popovers" do
    it "includes popover targets when show_popover is true" do
      render_inline(described_class.new(users: users.take(2), show_popover: true))

      expect(page).to have_css('[data-avatar-group-target="popover"]')
    end

    it "excludes popover targets when show_popover is false" do
      render_inline(described_class.new(users: users.take(2), show_popover: false))

      expect(page).not_to have_css('[data-avatar-group-target="popover"]')
    end

    it "includes user full name in popover" do
      user = users.first
      render_inline(described_class.new(users: [user], show_popover: true))

      expect(page).to have_text(user.full_name)
    end
  end

  describe "profile links" do
    it "includes profile links when link_to_profile is true" do
      render_inline(described_class.new(users: users.take(2), link_to_profile: true))

      expect(page).to have_link("View Profile")
    end

    it "excludes profile links when link_to_profile is false" do
      render_inline(described_class.new(users: users.take(2), link_to_profile: false))

      expect(page).not_to have_link("View Profile")
    end
  end

  describe "sizes" do
    it "applies sm size overlap by default" do
      render_inline(described_class.new(users: users.take(2)))

      expect(page).to have_css(".avatar-group.-space-x-3")
    end

    it "applies xs size overlap" do
      render_inline(described_class.new(users: users.take(2), size: :xs))

      expect(page).to have_css(".avatar-group.-space-x-2")
    end

    it "applies md size overlap" do
      render_inline(described_class.new(users: users.take(2), size: :md))

      expect(page).to have_css(".avatar-group.-space-x-4")
    end

    it "applies lg size overlap" do
      render_inline(described_class.new(users: users.take(2), size: :lg))

      expect(page).to have_css(".avatar-group.-space-x-5")
    end
  end

  describe "custom css_class" do
    it "appends custom class to container" do
      render_inline(described_class.new(users: users.take(2), css_class: "my-custom-class"))

      expect(page).to have_css(".avatar-group.my-custom-class")
    end
  end

  describe "accessibility" do
    it "includes role=button on avatar triggers" do
      render_inline(described_class.new(users: users.take(2)))

      expect(page).to have_css('[role="button"]')
    end

    it "includes aria-haspopup on avatar triggers" do
      render_inline(described_class.new(users: users.take(2)))

      expect(page).to have_css('[aria-haspopup="true"]')
    end

    it "includes aria-label with user name" do
      user = users.first
      render_inline(described_class.new(users: [user]))

      expect(page).to have_css("[aria-label=\"View #{user.full_name} profile\"]")
    end

    it "includes role=tooltip on popovers" do
      render_inline(described_class.new(users: users.take(2), show_popover: true))

      expect(page).to have_css('[role="tooltip"]')
    end
  end

  describe "role display" do
    let(:project) { create(:project) }
    let(:user_with_role) do
      user = create(:user)
      allow(user).to receive(:role_in_project).with(project).and_return(:admin)
      user
    end

    it "displays role when role_method is provided" do
      render_inline(described_class.new(
        users: [user_with_role],
        role_method: :role_in_project,
        role_context: project,
        show_popover: true
      ))

      expect(page).to have_text("Admin")
    end
  end
end
