require 'rails_helper'

CHROME_AVAILABLE = begin
  %w[google-chrome chrome chromium chromium-browser].any? { |cmd| system("which #{cmd} >/dev/null 2>&1") }
rescue StandardError
  false
end

RSpec.describe "Complete User Journey", type: :system, js: true do
  before do
    # skip "Chrome/Chromium not available; skipping JS system spec" unless CHROME_AVAILABLE
  end
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }

  describe "End-to-End User Workflow" do
    it "completes a full collaboration workflow from project creation to completion" do
      # Step 1: Alice signs up and creates a project
      visit "/"
      expect(page).to have_content("FlukeBase")

      # Sign in Alice
      sign_in alice
      visit dashboard_path

      # Create a new project
      visit new_project_path

      fill_in "Name", with: "AI Startup Platform"
      fill_in "Description", with: "Building the next generation AI platform for startups"
      select "Prototype", from: "Stage"

      click_button "Create Project"

      expect(page).to have_content("Project was successfully created")
      expect(page).to have_content("AI Startup Platform")

      project = Project.last

      # Step 2: Alice creates milestones for the project
      visit project_path(project)
      click_link "Add Milestone", match: :first

      fill_in "Title", with: "Build MVP Backend"
      fill_in "Description", with: "Create the core API and database structure"

      click_button "Create Milestone"

      expect(page).to have_content("Milestone was successfully created")
      milestone = project.milestones.last

      # Step 3: Alice creates an agreement with Bob
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)

      # Fill out agreement form
      # select project.name, from: "Project" # Removed as redundant with project_id param
      # fill_in "Other Party", with: bob.email # Removed as passed in URL
      fill_in "Start date", with: Date.current
      fill_in "End date", with: Date.current + 6.months
      choose "Hourly Rate"
      fill_in "Hourly Rate", with: "75"
      fill_in "Weekly Hours", with: "20"
      fill_in "Tasks", with: "Backend development and API design"
      check milestone.title

      click_button "Create Agreement"

      expect(page).to have_content("Agreement proposal sent to Bob Johnson!")
      agreement = Agreement.last

      # Step 4: Bob receives and accepts the agreement
      sign_in bob
      visit agreement_path(agreement)

      expect(page).to have_content("Status: Pending")
      expect(page).to have_content("AI Startup Platform")
      expect(page).to have_content("75.0$/hour")

      click_button "Accept Agreement"

      expect(page).to have_content("Agreement was successfully accepted")
      expect(page).to have_content("Status: Accepted")

      # Step 5: Bob starts working and logs time
      visit time_logs_path

      # Create a manual time log
      click_link "New Time Log"
      select project.name, from: "Project"
      select milestone.title, from: "Milestone"
      fill_in "Description", with: "Set up database schema and user authentication"
      fill_in "Hours", with: "8"
      fill_in "Date", with: Date.current.strftime("%Y-%m-%d")

      click_button "Create Time Log"

      expect(page).to have_content("Time log was successfully created")
      expect(page).to have_content("8.0 hours")

      # Step 6: Alice and Bob communicate about progress
      sign_in alice
      visit conversations_path

      click_link "New Conversation"
      fill_in "To", with: bob.email
      fill_in "Subject", with: "Backend Progress Update"
      fill_in "Message", with: "How's the database setup going? Any blockers?"

      click_button "Send Message"

      expect(page).to have_content("Message sent successfully")

      # Step 7: Bob responds to Alice
      sign_in bob
      visit conversations_path
      click_link "Backend Progress Update"

      fill_in "message_body", with: "Database is set up! Working on the API endpoints now. Should be done by Friday."
      click_button "Send Reply"

      expect(page).to have_content("Should be done by Friday")

      # Step 8: Alice marks milestone as complete
      sign_in alice
      visit milestone_path(milestone)

      click_button "Mark Complete"

      expect(page).to have_content("Milestone was successfully completed")

      # Step 9: Alice completes the agreement
      visit agreement_path(agreement)

      click_button "Complete"

      expect(page).to have_content("Agreement was successfully completed")
      expect(page).to have_content("Status: Completed")
    end

    it "handles counter offer negotiation workflow" do
      alice = create(:user, :alice)
      bob = create(:user, :bob)
      project = create(:project, user: alice)
      milestone = create(:milestone, project:)

      # Alice creates agreement
      sign_in alice
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)

      fill_in "Start date", with: Date.current
      fill_in "End date", with: Date.current + 6.months
      choose "Hourly Rate"
      fill_in "Hourly Rate", with: "60"
      fill_in "Weekly Hours", with: "15"
      fill_in "Tasks", with: "Frontend development"
      check milestone.title

      click_button "Create Agreement"

      agreement = Agreement.last

      # Bob makes counter offer
      sign_in bob
      visit agreement_path(agreement)

      click_button "Counter Offer"
      fill_in "Additional Terms", with: "I'd like to increase the rate to $70/hour and reduce hours to 10/week"
      click_button "Counter Offer"

      expect(page).to have_content("Counter offer was successfully created")

      # Alice reviews and accepts counter offer
      sign_in alice
      visit agreement_path(agreement)

      expect(page).to have_content("Status: Countered")
      click_link "View Latest Counter Offer" # Click the link to go to the counter offer agreement

      expect(page).to have_content("Counter Offer") # Ensure we are on the counter offer page
      click_button "Accept Agreement" # Accept the counter offer (which is a new agreement)

      expect(page).to have_content("Counter offer accepted")
      expect(page).to have_content("Status: Accepted")
    end

    it "handles project collaboration with multiple agreements" do
      alice = create(:user, :alice)
      bob = create(:user, :bob)
      charlie = create(:user, :charlie)
      project = create(:project, user: alice)
      create(:milestone, project:) # Ensure project has milestones

      # Alice creates agreements with both Bob and Charlie
      sign_in alice

      # Agreement with Bob
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)
      fill_in "Start date", with: Date.current
      fill_in "End date", with: Date.current + 6.months
      choose "Hourly Rate"
      fill_in "Hourly Rate", with: "75"
      fill_in "Weekly Hours", with: "20"
      fill_in "Tasks", with: "Backend development"
      check "Build MVP Feature"
      click_button "Create Agreement"

      # Agreement with Charlie
      visit new_agreement_path(project_id: project.id, other_party_id: charlie.id)
      fill_in "Start date", with: Date.current
      fill_in "End date", with: Date.current + 6.months
      choose "Hourly Rate"
      fill_in "Hourly Rate", with: "65"
      fill_in "Weekly Hours", with: "15"
      fill_in "Tasks", with: "Frontend development"
      check "Build MVP Feature"
      click_button "Create Agreement"

      # Both agreements should be visible
      visit agreements_path
      expect(page).to have_content(bob.full_name)
      expect(page).to have_content(charlie.full_name)
    end
  end

  describe "Error Handling and Edge Cases" do
    it "handles form validation errors gracefully" do
      sign_in alice
      visit new_project_path

      # Submit form without required fields
      click_button "Create Project"

      expect(page).to have_content("can't be blank")
      expect(page).to have_content("Name can't be blank")

      # Form should still be filled with previous data
      fill_in "Name", with: "Test Project"
      fill_in "Description", with: "A test project description"
      click_button "Create Project"

      expect(page).to have_content("Project was successfully created")
    end
  end

  describe "Performance and Accessibility" do
    it "maintains good performance with large datasets" do
      # Create many projects and agreements
      sign_in alice

      10.times do |i|
        project = create(:project, user: alice, name: "Project #{i}")
        create(:milestone, project:, title: "Milestone #{i}")
      end

      visit projects_path

      # Should load efficiently
      expect(page).to have_content("Project 0")
      expect(page).to have_content("Project 9")
    end

    it "maintains accessibility standards" do
      sign_in alice
      visit dashboard_path

      # Check for proper heading structure
      expect(page).to have_css("h2, h3")

      # Check for proper form labels
      visit new_project_path
      expect(page).to have_css("label[for='project_name']")
      expect(page).to have_css("label[for='project_description']")

      # Check for proper button types
      expect(page).to have_css("button[type='submit']")
    end
  end
end
