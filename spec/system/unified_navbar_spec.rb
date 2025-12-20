require 'rails_helper'

CHROME_AVAILABLE = begin
  %w[google-chrome chrome chromium chromium-browser].any? { |cmd| system("which #{cmd} >/dev/null 2>&1") }
rescue StandardError
  false
end

RSpec.describe "Unified Navbar", type: :system, js: true do
  before do
    skip "Chrome/Chromium not available; skipping JS system spec" unless CHROME_AVAILABLE
  end

  let(:user) { create(:user) }
  let!(:project1) { create(:project, user:, name: "Project Alpha") }
  let!(:project2) { create(:project, user:, name: "Project Beta") }
  let!(:milestone1) { create(:milestone, project: project1, title: "Alpha Milestone", status: "pending") }
  let!(:milestone2) { create(:milestone, project: project2, title: "Beta Milestone", status: "pending") }

  before do
    sign_in user
  end

  describe "Context Navigation Bar" do
    it "displays the context nav bar for authenticated users" do
      visit dashboard_path

      expect(page).to have_css("[data-controller='context-nav']")
    end

    it "shows project selector in the context nav" do
      visit dashboard_path

      within("[data-controller='context-nav']") do
        expect(page).to have_button(text: /Select Project|Active/)
      end
    end

    it "allows selecting a project from the dropdown" do
      visit dashboard_path

      within("[data-controller='context-nav']") do
        # Click the project selector
        find("details.dropdown summary", match: :first).click

        # Wait for dropdown to open and click project
        expect(page).to have_content("Project Alpha")
        click_button("Project Alpha")
      end

      # The context nav should update to show the selected project
      within("[data-controller='context-nav']") do
        expect(page).to have_content("Project Alpha")
      end
    end

    it "shows milestone dropdown when a project is selected" do
      user.update(selected_project_id: project1.id)
      visit dashboard_path

      within("[data-controller='context-nav']") do
        expect(page).to have_button("Milestones")
      end
    end

    it "displays milestones for the selected project" do
      user.update(selected_project_id: project1.id)
      visit dashboard_path

      within("[data-controller='context-nav']") do
        click_button("Milestones")
        expect(page).to have_content("Alpha Milestone")
      end
    end

    it "shows quick action buttons when project is selected" do
      user.update(selected_project_id: project1.id)
      visit dashboard_path

      within("[data-controller='context-nav']") do
        expect(page).to have_link("Details")
        expect(page).to have_link("Milestone")
        expect(page).to have_link("Time")
        expect(page).to have_link("GitHub")
      end
    end

    it "updates quick action links when project changes" do
      user.update(selected_project_id: project1.id)
      visit dashboard_path

      within("[data-controller='context-nav']") do
        expect(page).to have_link("Details", href: project_path(project1))
      end

      # Switch to project 2
      within("[data-controller='context-nav']") do
        find("details.dropdown summary", match: :first).click
        click_button("Project Beta")
      end

      # Wait for Turbo update
      expect(page).to have_content("Project Beta")

      within("[data-controller='context-nav']") do
        expect(page).to have_link("Details", href: project_path(project2))
      end
    end
  end

  describe "Main Navbar Changes" do
    it "does not show the project selector in the main navbar" do
      visit dashboard_path

      within("nav.navbar") do
        # The "Working on:" text was in the old navbar project selector
        expect(page).not_to have_text("Working on:")
      end
    end

    it "retains navigation links in the main navbar" do
      visit dashboard_path

      within("nav.navbar") do
        expect(page).to have_link("Dashboard")
        expect(page).to have_link("Projects")
        expect(page).to have_link("Agreements")
        expect(page).to have_link("Messages")
      end
    end
  end

  describe "Milestone Dropdown Functionality" do
    before do
      user.update(selected_project_id: project1.id)
    end

    it "shows milestone list in the dropdown" do
      visit dashboard_path

      within("[data-controller='context-nav']") do
        click_button("Milestones")

        expect(page).to have_content("Alpha Milestone")
        expect(page).to have_content("Project Milestones")
      end
    end

    it "updates milestone list when project changes" do
      visit dashboard_path

      # First, check milestones for project1
      within("[data-controller='context-nav']") do
        click_button("Milestones")
        expect(page).to have_content("Alpha Milestone")
        expect(page).not_to have_content("Beta Milestone")
      end

      # Close the dropdown
      find("body").click

      # Switch to project2
      within("[data-controller='context-nav']") do
        find("details.dropdown summary", match: :first).click
        click_button("Project Beta")
      end

      # Wait for Turbo update and check new milestones
      expect(page).to have_content("Project Beta")

      within("[data-controller='context-nav']") do
        click_button("Milestones")
        expect(page).to have_content("Beta Milestone")
        expect(page).not_to have_content("Alpha Milestone")
      end
    end
  end

  describe "Project Switching Without Project" do
    it "shows helpful message when no project is selected" do
      visit dashboard_path

      within("[data-controller='context-nav']") do
        expect(page).to have_content("Select a project to get started")
      end
    end
  end

  describe "In-Place Turbo Updates" do
    context "on GitHub Logs page" do
      let!(:github_log1) { create(:github_log, project: project1, commit_message: "Alpha commit") }
      let!(:github_log2) { create(:github_log, project: project2, commit_message: "Beta commit") }

      before do
        user.update(selected_project_id: project1.id)
      end

      it "updates GitHub logs content when switching projects" do
        visit project_github_logs_path(project1)

        expect(page).to have_content("GitHub Activity for Project Alpha")

        # Switch project via context nav
        within("[data-controller='context-nav']") do
          find("details.dropdown summary", match: :first).click
          click_button("Project Beta")
        end

        # Content should update via Turbo
        expect(page).to have_content("Project Beta")
      end
    end

    context "on Time Logs page" do
      before do
        user.update(selected_project_id: project1.id)
      end

      it "updates milestones section when switching projects" do
        visit time_logs_path(project1)

        expect(page).to have_content("Alpha Milestone")

        # Switch project via context nav
        within("[data-controller='context-nav']") do
          find("details.dropdown summary", match: :first).click
          click_button("Project Beta")
        end

        # Content should update via Turbo
        expect(page).to have_content("Beta Milestone")
      end
    end
  end

  describe "Dropdown Interactions" do
    it "closes project dropdown when clicking outside" do
      user.update(selected_project_id: project1.id)
      visit dashboard_path

      within("[data-controller='context-nav']") do
        find("details.dropdown summary", match: :first).click
        expect(page).to have_content("Switch Project Context")
      end

      # Click outside to close
      find("body").click

      within("[data-controller='context-nav']") do
        expect(page).not_to have_content("Switch Project Context")
      end
    end

    it "closes milestone dropdown when clicking outside" do
      user.update(selected_project_id: project1.id)
      visit dashboard_path

      within("[data-controller='context-nav']") do
        click_button("Milestones")
        expect(page).to have_content("Project Milestones")
      end

      # Click outside to close
      find("body").click

      within("[data-controller='context-nav']") do
        expect(page).not_to have_content("Project Milestones")
      end
    end

    it "only allows one dropdown open at a time" do
      user.update(selected_project_id: project1.id)
      visit dashboard_path

      within("[data-controller='context-nav']") do
        # Open project dropdown
        find("details.dropdown summary", match: :first).click
        expect(page).to have_content("Switch Project Context")

        # Open milestone dropdown
        click_button("Milestones")

        # Project dropdown should close
        expect(page).not_to have_content("Switch Project Context")
        expect(page).to have_content("Project Milestones")
      end
    end
  end
end
