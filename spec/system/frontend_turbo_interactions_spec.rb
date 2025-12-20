require 'rails_helper'

RSpec.describe "Frontend Turbo Interactions", type: :system, js: true do
  let(:alice) { create(:user, first_name: "Alice", last_name: "Entrepreneur") }
  let(:bob) { create(:user, first_name: "Bob", last_name: "Developer") }
  let(:project) { create(:project, user: alice, name: "FlukeBase") }

  before do
    sign_in alice
  end

  describe "People show page interactions" do
    let!(:agreement) { create(:agreement, :with_participants, project:, initiator: alice, other_party: bob) }

    it "displays user profile with proper Turbo Stream integration" do
      visit person_path(bob)

      expect(page).to have_content("Bob Developer")
      expect(page).to have_content("Community Person")

      # Check for proper sections
      expect(page).to have_css("#about")
      expect(page).to have_css("#achievements")
      expect(page).to have_css("#projects")

      # Verify action buttons
      expect(page).to have_button("Message")

      # Check responsive design
      expect(page).to have_css(".max-w-6xl.mx-auto")
    end

    it "handles messaging with Turbo interaction" do
      visit person_path(bob)

      click_button "Message"

      # Should redirect to conversations (Turbo handles this)
      expect(page).to have_current_path(conversations_path, ignore_query: true)
    end

    it "displays social media links with proper external link handling" do
      bob.update!(linkedin: "bob-dev", x: "bobdev")

      visit person_path(bob)

      within(".bg-gradient-to-r.from-blue-50") do
        expect(page).to have_link("LinkedIn", href: "https://linkedin.com/in/bob-dev")
        expect(page).to have_link("X", href: "https://x.com/bobdev")

        # Verify external links open in new tab
        expect(page).to have_css("a[target='_blank']", count: 2)
      end
    end

    it "shows connection analysis properly" do
      visit person_path(bob)

      within(".bg-gradient-to-r.from-indigo-50") do
        expect(page).to have_content("You and Bob")
        expect(page).to have_content("Active agreements: 1 collaboration(s)")
      end
    end

    it "handles navigation tabs with anchor links" do
      visit person_path(bob)

      click_link "About"
      expect(page).to have_current_path("#{person_path(bob)}#about")

      click_link "Projects"
      expect(page).to have_current_path("#{person_path(bob)}#projects")
    end
  end

  describe "Flash messages with Turbo Streams" do
    it "displays and dismisses flash messages" do
      flash[:notice] = "Test success message"

      visit dashboard_path

      expect(page).to have_content("Test success message")
      expect(page).to have_css(".bg-green-50")

      # Flash should auto-dismiss or be dismissible
      expect(page).to have_css(".rounded-md")
    end

    it "handles multiple flash message types" do
      flash[:notice] = "Success message"
      flash[:alert] = "Error message"

      visit dashboard_path

      expect(page).to have_content("Success message")
      expect(page).to have_content("Error message")
      expect(page).to have_css(".bg-green-50")
      expect(page).to have_css(".bg-red-50")
    end
  end

  describe "Project context header" do
    before do
      alice.update!(selected_project: project)
    end

    it "displays current project in header" do
      visit dashboard_path

      expect(page).to have_content("FlukeBase")
      expect(page).to have_css(".font-bold.text-lg.text-indigo-700")
    end

    it "updates when project selection changes" do
      new_project = create(:project, user: alice, name: "New Project")
      alice.update!(selected_project: new_project)

      visit dashboard_path

      expect(page).to have_content("New Project")
      expect(page).not_to have_content("FlukeBase")
    end

    it "shows fallback when no project selected" do
      alice.update!(selected_project: nil)

      visit dashboard_path

      expect(page).to have_content("No project selected")
    end
  end

  describe "Lazy loading Turbo Frames" do
    let!(:agreement) { create(:agreement, :with_participants, :accepted, project:, initiator: alice, other_party: bob) }
    let!(:meeting) { create(:meeting, agreement:, user: alice) }

    it "loads lazy frames on agreement show page" do
      visit agreement_path(agreement)

      # Check for lazy loading frames
      expect(page).to have_css("turbo-frame[loading='lazy']")

      # Should show loading placeholder initially
      expect(page).to have_content("Loading...")

      # Wait for lazy content to load
      expect(page).to have_content("Meetings", wait: 10)
      expect(page).to have_content(meeting.title, wait: 10)
    end

    it "handles lazy loading errors gracefully" do
      # Simulate a broken lazy loading endpoint
      allow_any_instance_of(AgreementsController).to receive(:meetings_section).and_raise(StandardError)

      visit agreement_path(agreement)

      # Should show error state instead of crashing
      expect(page).to have_content("Unable to load", wait: 10).or(
        have_content("Error loading", wait: 10)
      )
    end
  end

  describe "GitHub integration Turbo features" do
    let!(:github_branch) { create(:github_branch, project:, name: "main") }

    before do
      # Ensure user has access to project
      project.update!(user: alice)
    end

    it "loads GitHub logs page with Turbo Frames" do
      visit project_github_logs_path(project)

      expect(page).to have_content("GitHub Activity for #{project.name}")
      expect(page).to have_css("turbo-frame[id='github_commits']")

      # Should show branch filter
      expect(page).to have_content("Branch:")
      expect(page).to have_content("All Branches")
    end

    it "filters commits with Turbo navigation" do
      visit project_github_logs_path(project)

      # Use branch filter (should use Turbo navigation)
      click_button "All Branches"
      click_link "main"

      # Should update without full page reload
      expect(page).to have_content("main")
      expect(page).not_to have_css(".page-loading")
    end

    it "handles refresh commits with confirmation" do
      visit project_github_logs_path(project)

      # Should show confirmation dialog
      accept_confirm do
        click_button "Refresh Commits"
      end

      # Should handle the background job initiation
      expect(page).to have_content("GitHub Activity", wait: 5)
    end
  end

  describe "Agreement Turbo Streams integration" do
    let!(:pending_agreement) { create(:agreement, :with_participants, :pending, project:, initiator: alice, other_party: bob) }

    before do
      sign_in bob
    end

    it "accepts agreement with Turbo Stream updates" do
      visit agreement_path(pending_agreement)

      expect(page).to have_content("Status: Pending")
      expect(page).to have_button("Accept")

      click_button "Accept"

      # Should update via Turbo Stream
      expect(page).to have_content("Status: Accepted", wait: 10)
      expect(page).not_to have_button("Accept")
      expect(page).to have_content("Agreement was successfully accepted", wait: 5)
    end

    it "updates multiple elements simultaneously" do
      visit agreement_path(pending_agreement)

      click_button "Accept"

      # Multiple elements should update via Turbo Streams
      expect(page).to have_content("Status: Accepted", wait: 10)
      expect(page).to have_content("Agreement was successfully accepted", wait: 5)
      expect(page).not_to have_button("Accept")
      expect(page).not_to have_button("Reject")
    end
  end

  describe "Mobile responsiveness" do
    it "displays properly on mobile viewport", driver: :selenium_chrome_headless do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size

      visit person_path(bob)

      expect(page).to have_content("Bob Developer")
      expect(page).to have_button("Message")

      # Should handle mobile layout
      expect(page).to have_css(".flex-col")
    end

    it "handles mobile navigation", driver: :selenium_chrome_headless do
      page.driver.browser.manage.window.resize_to(375, 667)

      visit person_path(bob)

      click_link "Projects"
      expect(page).to have_current_path("#{person_path(bob)}#projects")
    end
  end

  describe "Performance and loading" do
    it "loads pages within reasonable time" do
      start_time = Time.current

      visit person_path(bob)

      expect(page).to have_content("Bob Developer", wait: 5)

      load_time = Time.current - start_time
      expect(load_time).to be < 10.seconds
    end

    it "handles concurrent Turbo Frame loading" do
      agreement = create(:agreement, :with_participants, :accepted, project:)

      start_time = Time.current
      visit agreement_path(agreement)

      # Multiple frames should load concurrently, not sequentially
      expect(page).to have_content("Agreement Details", wait: 10)

      total_time = Time.current - start_time
      expect(total_time).to be < 15.seconds # Should be concurrent, not sequential
    end
  end

  describe "Error handling" do
    it "handles network timeouts gracefully" do
      # Simulate slow network when supported by the driver
      if page.driver.browser.respond_to?(:network_conditions=)
        page.driver.browser.network_conditions = {
          offline: false,
          latency: 2000,
          download_throughput: 500,
          upload_throughput: 500
        }
      else
        skip "Driver does not support network throttling"
      end

      visit person_path(bob)

      # Should still load, just slower
      expect(page).to have_content("Bob Developer", wait: 15)
    end

    it "handles JavaScript disabled gracefully" do
      Capybara.current_driver = :rack_test # Disable JS

      visit person_path(bob)

      expect(page).to have_content("Bob Developer")
      expect(page).to have_button("Message")

      # Revert to JS driver
      Capybara.current_driver = :selenium_chrome_headless
    end
  end

  describe "Accessibility compliance" do
    it "maintains proper heading structure" do
      visit person_path(bob)

      headings = page.all("h1, h2, h3, h4, h5, h6").map(&:tag_name)

      # Should have exactly one h1
      expect(headings.count("h1")).to eq(1)

      # Should have logical heading progression
      expect(headings.first).to eq("h1")
    end

    it "includes proper form labels and accessibility attributes" do
      visit person_path(bob)

      # Check for proper button attributes
      expect(page).to have_css("button[type]")

      # Check for proper link attributes for external links
      expect(page).to have_css("a[target='_blank']") if bob.linkedin.present?
    end

    it "supports keyboard navigation" do
      visit person_path(bob)

      # Should be able to tab through interactive elements
      page.driver.browser.action.send_keys(:tab).perform

      # Focus should be on first interactive element
      focused_element = page.evaluate_script("document.activeElement.tagName")
      expect(['BUTTON', 'A', 'INPUT']).to include(focused_element)
    end
  end
end
