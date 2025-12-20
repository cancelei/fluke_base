require 'rails_helper'

RSpec.describe 'Stimulus Timer Controller', type: :system, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:, public_fields: ['name']) }
  let!(:milestone) { create(:milestone, project:, title: 'Kickoff Sync', status: Milestone::PENDING) }

  before do
    sign_in user
  end

  it 'starts and stops the timer when tracking a milestone' do
    visit project_time_logs_path(project)

    expect(page).to have_css("#milestone_#{milestone.id}", wait: 5)

    within("#milestone_#{milestone.id}") do
      accept_confirm do
        click_button 'Start Tracking'
      end
    end

    expect(page).to have_css("[data-controller*='timer']", wait: 5)
    expect_stimulus_controller('timer', "[data-controller*='timer']")

    timer_selector = "[data-controller*='timer'] [data-timer-target='timer']"
    expect(page).to have_css(timer_selector, text: /\A\d{2}:\d{2}:\d{2}\z/, wait: 5)

    initial_time = find(timer_selector, visible: :all).text
    sleep 1
    expect(find(timer_selector, visible: :all).text).not_to eq(initial_time)

    click_button 'Stop'

    expect(page).to have_css('#flash_messages', text: 'Stopped tracking time.', wait: 5)
    within("#milestone_#{milestone.id}") do
      expect(page).to have_button('Start Tracking', wait: 5)
    end
  end
end
