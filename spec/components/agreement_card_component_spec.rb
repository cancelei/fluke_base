# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgreementCardComponent, type: :component do
  let(:user) { create(:user, first_name: "Project", last_name: "Owner") }
  let(:other_user) { create(:user, first_name: "Other", last_name: "User") }
  let(:project) { create(:project, user:, name: "Test Project") }
  let(:agreement) { create(:agreement, project:, initiator: user, other_party: other_user) }

  describe "render?" do
    it "renders when agreement is present" do
      component = described_class.new(agreement:, current_user: user)

      expect(component.render?).to be true
    end

    it "does not render when agreement is nil" do
      component = described_class.new(agreement: nil, current_user: user)

      expect(component.render?).to be_falsey
    end
  end

  describe "rendering" do
    it "renders as tr element" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_css("tr")
    end

    it "renders with dom_id" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_css("tr#agreement_#{agreement.id}")
    end

    it "renders multiple cells" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_css("td", minimum: 5)
    end
  end

  describe "project cell" do
    it "renders project name for initiator" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_css("td.px-2.py-2")
    end
  end

  describe "party cell" do
    it "shows other party name for initiator" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_text("Other User")
    end

    it "shows project owner name for other party" do
      render_inline(described_class.new(agreement:, current_user: other_user))

      expect(page).to have_text("Project Owner")
    end
  end

  describe "status cell" do
    it "renders status badge" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_text(agreement.status.humanize)
    end
  end

  describe "actions cell" do
    it "renders view link by default" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_link("View")
    end

    it "hides actions when show_actions is false" do
      render_inline(described_class.new(agreement:, current_user: user, show_actions: false))

      expect(page).not_to have_link("View")
    end

    it "renders view link with correct path" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_link("View", href: "/agreements/#{agreement.id}")
    end

    it "renders view link with correct styling" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_css("a.text-indigo-600")
    end
  end

  describe "time remaining cell" do
    it "renders time remaining column" do
      render_inline(described_class.new(agreement:, current_user: user))

      expect(page).to have_css("td.text-right.text-sm.font-medium")
    end
  end
end
