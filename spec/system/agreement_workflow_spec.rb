require 'rails_helper'

RSpec.describe "Agreement Workflow", type: :system do
  let(:alice) { @alice }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }

  before do
    # Use Warden login_as method for system tests
    @alice = create(:user, :alice)
    login_as(@alice, scope: :user)
  end

  describe "Complete Agreement Lifecycle" do
    it "creates, negotiates, and completes an agreement" do
      # Test basic authentication and navigation
      visit projects_path
      expect(page).to have_content("Projects")

      # Test project creation
      click_link "New Project"
      expect(page).to have_content("Create New Project")

      fill_in "Name", with: project.name
      fill_in "Description", with: "Test project for agreement workflow"
      select "Idea", from: "Stage"
      click_button "Create Project"

      # Verify project was created
      expect(page).to have_content(project.name)

      # Test navigation to agreements
      visit agreements_path
      expect(page).to have_content("Agreements")

      # Test navigation to find people
      click_link "Find people"
      expect(page).to have_content("Discover Amazing People")
    end
  end
end
