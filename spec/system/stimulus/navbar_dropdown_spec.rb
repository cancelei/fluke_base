require 'rails_helper'

RSpec.describe 'Stimulus Dropdown Controller', type: :system, js: true do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user:, name: 'Navigation Project') }

  before do
    sign_in user
    visit dashboard_path
  end

  it 'opens and closes dropdown menus while coordinating between instances' do
    dropdowns = all("[data-controller='dropdown']", minimum: 2)

    explore_dropdown = dropdowns.find { |node| node.has_text?('Explore') }
    project_dropdown = dropdowns.find { |node| node.has_text?('Select Project') || node.has_text?(project.name) }

    expect(explore_dropdown).to be_present
    expect(project_dropdown).to be_present

    within(explore_dropdown) do
      click_button('Explore')
      expect(page).to have_css("[data-dropdown-target='menu']:not(.hidden)", visible: :all, wait: 2)
    end

    within(project_dropdown) do
      click_button(match: :first)
      expect(page).to have_css("[data-dropdown-target='menu']:not(.hidden)", visible: :all, wait: 2)
    end

    within(explore_dropdown) do
      expect(page).to have_css("[data-dropdown-target='menu'].hidden", visible: :all, wait: 2)
    end

    # Clicking outside should close the remaining open dropdown
    find('body').click
    within(project_dropdown) do
      expect(page).to have_css("[data-dropdown-target='menu'].hidden", visible: :all, wait: 2)
    end
  end
end
