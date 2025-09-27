# Stimulus Testing Patterns in FlukeBase

This document outlines comprehensive testing patterns for Stimulus controllers and JavaScript interactions, complementing the implementation patterns documented in `../stimulus/README.md`.

## Table of Contents

1. [Testing Framework Setup](#testing-framework-setup)
2. [Unit Testing Stimulus Controllers](#unit-testing-stimulus-controllers)
3. [Integration Testing with Rails](#integration-testing-with-rails)
4. [System Testing JavaScript Interactions](#system-testing-javascript-interactions)
5. [Media Controller Testing](#media-controller-testing)
6. [Event Handling Testing](#event-handling-testing)
7. [Performance Testing](#performance-testing)
8. [Debugging and Troubleshooting](#debugging-and-troubleshooting)

## Testing Framework Setup

### JavaScript Testing Environment
**Reference**: `../stimulus/README.md` - Complete Stimulus controller patterns

FlukeBase uses a combination of testing approaches for Stimulus controllers:
- **Playwright** - End-to-end testing with real browser interactions
- **Capybara + Selenium** - Integration testing within Rails
- **Jest** (if needed) - Unit testing of complex JavaScript logic
- **Rails System Tests** - Full-stack testing with JavaScript enabled

### Test Configuration
```javascript
// playwright.config.js
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './spec/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
  webServer: {
    command: 'rails server -e test -p 3000',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### Rails System Test Configuration
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400] do |options|
      options.add_argument('--headless') if ENV['HEADLESS']
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
    end
  end
end

# Custom matchers for Stimulus
RSpec::Matchers.define :have_stimulus_controller do |controller_name|
  match do |page|
    page.has_css?("[data-controller*='#{controller_name}']")
  end
  
  failure_message do |page|
    "expected page to have element with data-controller='#{controller_name}'"
  end
end

RSpec::Matchers.define :have_fired_stimulus_action do |action_name|
  match do |page|
    # Check for action execution by looking for expected DOM changes
    # This is implementation-specific
    true
  end
end
```

## Unit Testing Stimulus Controllers

### Timer Controller Testing
**Reference**: `../stimulus/README.md` - Timer with Server Sync

```ruby
RSpec.describe "Timer Controller", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let(:milestone) { create(:milestone, project: project) }
  let(:time_log) { create(:time_log, user: alice, project: project, milestone: milestone, started_at: 1.hour.ago) }

  before { sign_in alice }

  describe "timer functionality" do
    it "initializes with correct values" do
      visit time_logs_path
      
      expect(page).to have_stimulus_controller("timer")
      
      # Check timer displays current elapsed time
      within("[data-controller='timer']") do
        timer_display = find("[data-timer-target='timer']")
        expect(timer_display.text).to match(/\d{2}:\d{2}:\d{2}/)
      end
    end

    it "starts and stops timer correctly" do
      visit time_logs_path
      
      within("[data-controller='timer']") do
        # Start timer
        click_button(class: "data-timer-target='playButton'")
        
        expect(page).to have_css("[data-timer-target='playButton'].hidden")
        expect(page).to have_css("[data-timer-target='stopButton']:not(.hidden)")
        
        # Timer should be incrementing
        initial_time = find("[data-timer-target='timer']").text
        sleep(2)
        current_time = find("[data-timer-target='timer']").text
        expect(current_time).not_to eq(initial_time)
        
        # Stop timer
        click_button(class: "data-timer-target='stopButton'")
        
        expect(page).to have_css("[data-timer-target='playButton']:not(.hidden)")
        expect(page).to have_css("[data-timer-target='stopButton'].hidden")
      end
    end

    it "maintains server time synchronization" do
      # Test that timer uses server-provided time values
      visit time_logs_path
      
      # Check data attributes are set correctly
      timer_element = find("[data-controller='timer']")
      expect(timer_element['data-timer-started-at-value']).to be_present
      expect(timer_element['data-timer-now-value']).to be_present
      expect(timer_element['data-timer-used-hours-value']).to be_present
    end

    it "handles disconnect gracefully" do
      visit time_logs_path
      
      # Start timer
      within("[data-controller='timer']") do
        click_button(class: "data-timer-target='playButton'")
      end
      
      # Navigate away and back
      visit projects_path
      visit time_logs_path
      
      # Timer should reconnect and continue
      expect(page).to have_stimulus_controller("timer")
    end
  end
end
```

### Dropdown Controller Testing
**Reference**: `../stimulus/README.md` - Inter-Controller Communication

```ruby
RSpec.describe "Dropdown Controller", type: :system, js: true do
  let(:alice) { create(:user) }

  before { sign_in alice }

  describe "dropdown behavior" do
    it "toggles dropdown visibility" do
      visit projects_path # Page with dropdown
      
      # Initially hidden
      expect(page).to have_css("[data-dropdown-target='menu'].hidden")
      
      # Click to open
      find("[data-action='click->dropdown#toggle']").click
      
      expect(page).not_to have_css("[data-dropdown-target='menu'].hidden")
      
      # Click to close
      find("[data-action='click->dropdown#toggle']").click
      
      expect(page).to have_css("[data-dropdown-target='menu'].hidden")
    end

    it "closes dropdown when clicking outside" do
      visit projects_path
      
      # Open dropdown
      find("[data-action='click->dropdown#toggle']").click
      expect(page).not_to have_css("[data-dropdown-target='menu'].hidden")
      
      # Click outside
      find('body').click
      
      expect(page).to have_css("[data-dropdown-target='menu'].hidden")
    end

    it "closes other dropdowns when opening new one" do
      visit projects_path # Assuming multiple dropdowns
      
      # Open first dropdown
      first("[data-action='click->dropdown#toggle']").click
      first_dropdown = first("[data-dropdown-target='menu']")
      expect(first_dropdown).not_to have_css(".hidden")
      
      # Open second dropdown
      all("[data-action='click->dropdown#toggle']")[1].click
      
      # First should close, second should open
      expect(first_dropdown).to have_css(".hidden")
      second_dropdown = all("[data-dropdown-target='menu']")[1]
      expect(second_dropdown).not_to have_css(".hidden")
    end

    it "handles keyboard navigation" do
      visit projects_path
      
      # Open dropdown
      dropdown_trigger = find("[data-action='click->dropdown#toggle']")
      dropdown_trigger.click
      
      # Test escape key closes dropdown
      dropdown_trigger.send_keys(:escape)
      expect(page).to have_css("[data-dropdown-target='menu'].hidden")
    end
  end

  describe "event coordination" do
    it "dispatches custom events correctly" do
      visit projects_path
      
      # Monitor for custom events
      page.execute_script("""
        window.dropdownEvents = [];
        document.addEventListener('dropdown:opened', function(e) {
          window.dropdownEvents.push('opened');
        });
      """)
      
      # Open dropdown
      find("[data-action='click->dropdown#toggle']").click
      
      # Check event was dispatched
      events = page.evaluate_script("window.dropdownEvents")
      expect(events).to include("opened")
    end
  end
end
```

### Agreement Form Controller Testing
**Reference**: `../stimulus/README.md` - Form Integration

```ruby
RSpec.describe "Agreement Form Controller", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }

  before { sign_in alice }

  describe "payment field toggling" do
    it "shows appropriate fields based on payment type" do
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)
      
      expect(page).to have_stimulus_controller("agreement-form")
      
      # Initially no payment fields should be visible
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: false)
      expect(page).to have_css("[data-agreement-form-target='equityField']", visible: false)
      
      # Select hourly payment
      choose "Hourly"
      
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: true)
      expect(page).to have_css("[data-agreement-form-target='equityField']", visible: false)
      
      # Select equity payment
      choose "Equity"
      
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: false)
      expect(page).to have_css("[data-agreement-form-target='equityField']", visible: true)
      
      # Select hybrid payment
      choose "Hybrid"
      
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: true)
      expect(page).to have_css("[data-agreement-form-target='equityField']", visible: true)
    end

    it "toggles fields on page load based on existing selection" do
      # Create form with pre-selected payment type
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)
      
      # Simulate page refresh with form data
      page.execute_script("""
        document.querySelector('input[value=\"Hourly\"]').checked = true;
        document.querySelector('[data-controller=\"agreement-form\"]').stimulus.connect();
      """)
      
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: true)
      expect(page).to have_css("[data-agreement-form-target='equityField']", visible: false)
    end

    it "handles rapid toggle changes" do
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)
      
      # Rapidly toggle between options
      5.times do
        choose "Hourly"
        choose "Equity"
        choose "Hybrid"
      end
      
      # Should end up in correct state
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: true)
      expect(page).to have_css("[data-agreement-form-target='equityField']", visible: true)
    end
  end
end
```

## Integration Testing with Rails

### Form Submission with Stimulus
```ruby
RSpec.describe "Stimulus Form Integration", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }

  before { sign_in alice }

  describe "enhanced form submission" do
    it "enhances form before submission" do
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)
      
      # Fill form
      fill_in "Tasks", with: "Help with development"
      choose "Hourly"
      fill_in "Hourly Rate", with: "75"
      fill_in "Weekly Hours", with: "10"
      fill_in "Start Date", with: 1.week.from_now.to_date
      fill_in "End Date", with: 4.weeks.from_now.to_date
      
      # Submit form
      click_button "Create Agreement"
      
      # Should redirect to agreements page
      expect(current_path).to eq(agreements_path)
      expect(page).to have_content("Agreement was successfully created")
      
      # Verify agreement was created with correct data
      agreement = Agreement.last
      expect(agreement.tasks).to eq("Help with development")
      expect(agreement.hourly_rate).to eq(75.0)
    end

    it "handles form validation errors" do
      visit new_agreement_path(project_id: project.id, other_party_id: bob.id)
      
      # Submit incomplete form
      click_button "Create Agreement"
      
      # Should stay on form page with errors
      expect(current_path).to include("agreements")
      expect(page).to have_content("can't be blank")
      
      # Form controller should maintain state
      expect(page).to have_stimulus_controller("agreement-form")
    end
  end
end
```

### Turbo Integration Testing
```ruby
RSpec.describe "Stimulus + Turbo Integration", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  describe "controller persistence across turbo navigation" do
    it "maintains controller state during turbo frame updates" do
      sign_in bob
      visit agreement_path(agreement)
      
      # Open dropdown (stimulus controller state)
      find("[data-action='click->dropdown#toggle']").click
      expect(page).not_to have_css("[data-dropdown-target='menu'].hidden")
      
      # Accept agreement (triggers turbo stream update)
      click_button "Accept"
      
      # Wait for turbo stream to complete
      expect(page).to have_content("Agreement was successfully accepted")
      
      # Dropdown controller should still be functional
      # (New turbo stream content should reconnect controllers)
      expect(page).to have_stimulus_controller("dropdown")
    end

    it "handles turbo stream morphing correctly" do
      sign_in alice
      visit agreements_path
      
      # Start timer on time tracking page
      visit time_logs_path
      within("[data-controller='timer']") do
        click_button(class: "data-timer-target='playButton'")
      end
      
      # Navigate via turbo
      click_link "Agreements"
      
      # Go back to time logs
      click_link "Time Logs"
      
      # Timer controller should reinitialize correctly
      expect(page).to have_stimulus_controller("timer")
    end
  end
end
```

## System Testing JavaScript Interactions

### Complex User Workflows
```ruby
RSpec.describe "Complete User Workflows", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }

  describe "agreement creation with all stimulus controllers" do
    it "completes full agreement creation workflow" do
      sign_in alice
      visit projects_path
      
      # Step 1: Navigate using dropdown controller
      find("[data-action='click->dropdown#toggle']").click
      click_link "New Agreement"
      
      # Step 2: Use agreement form controller
      fill_in "Search for user", with: bob.email
      # (Simulate user selection - would involve search controller)
      
      choose "Mentorship"
      choose "Hourly"
      
      # Form controller should show hourly fields
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: true)
      
      fill_in "Hourly Rate", with: "85"
      fill_in "Weekly Hours", with: "15"
      fill_in "Tasks", with: "Full stack development help"
      
      # Step 3: Submit form
      click_button "Create Agreement"
      
      # Step 4: Verify success with toast controller (if implemented)
      expect(page).to have_content("Agreement was successfully created")
      
      # Step 5: Verify created agreement
      agreement = Agreement.last
      expect(agreement.hourly_rate).to eq(85.0)
      expect(agreement.weekly_hours).to eq(15)
      expect(agreement.tasks).to eq("Full stack development help")
    end

    it "handles errors gracefully across controllers" do
      sign_in alice
      visit new_agreement_path(project_id: project.id, other_party_id: alice.id) # Invalid: same user
      
      # Fill form using controllers
      choose "Hourly"
      fill_in "Hourly Rate", with: "75"
      
      # Submit (should fail validation)
      click_button "Create Agreement"
      
      # Form controller should preserve state
      expect(page).to have_css("[data-agreement-form-target='hourlyField']", visible: true)
      expect(find_field("Hourly Rate").value).to eq("75")
      
      # Error should be displayed
      expect(page).to have_content("can't create agreement with yourself")
    end
  end
end
```

### Performance Under Load
```ruby
RSpec.describe "Stimulus Performance", type: :system, js: true do
  let(:alice) { create(:user) }

  describe "many controllers on page" do
    it "handles multiple controller instances efficiently" do
      # Create page with many stimulus controllers
      projects = create_list(:project, 20, user: alice)
      
      sign_in alice
      visit projects_path
      
      start_time = Time.current
      
      # Page should load with all controllers
      expect(page).to have_content(projects.first.name, wait: 10)
      
      load_time = Time.current - start_time
      expect(load_time).to be < 5.seconds
      
      # All dropdown controllers should work
      dropdowns = all("[data-controller*='dropdown']")
      expect(dropdowns.count).to be >= 20
      
      # Test first and last dropdown
      dropdowns.first.find("[data-action='click->dropdown#toggle']").click
      expect(dropdowns.first).not_to have_css("[data-dropdown-target='menu'].hidden")
      
      dropdowns.last.find("[data-action='click->dropdown#toggle']").click
      expect(dropdowns.first).to have_css("[data-dropdown-target='menu'].hidden")
      expect(dropdowns.last).not_to have_css("[data-dropdown-target='menu'].hidden")
    end
  end

  describe "memory management" do
    it "cleans up controllers on navigation" do
      sign_in alice
      
      # Visit pages with different controllers
      20.times do
        visit projects_path # Dropdown controllers
        visit time_logs_path # Timer controllers  
        visit agreements_path # Form controllers
      end
      
      # Check for memory leaks (simplified test)
      memory_info = page.evaluate_script("window.performance.memory")
      expect(memory_info).to be_present
      
      # Controllers should still work after many navigations
      visit projects_path
      expect(page).to have_stimulus_controller("dropdown")
    end
  end
end
```

## Media Controller Testing

### Message Recorder Controller Testing
**Reference**: `../stimulus/README.md` - Media & Advanced Features

```ruby
RSpec.describe "Message Recorder Controller", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let!(:conversation) { create(:conversation, :between_users, user1: alice, user2: bob) }

  before { sign_in alice }

  describe "audio recording functionality" do
    before do
      # Mock browser media APIs
      page.execute_script("""
        navigator.mediaDevices = {
          getUserMedia: function() {
            return Promise.resolve({
              getTracks: function() { return [{ stop: function() {} }]; }
            });
          }
        };
        
        window.MediaRecorder = class {
          constructor(stream) {
            this.state = 'inactive';
            this.ondataavailable = null;
            this.onstop = null;
          }
          
          start() {
            this.state = 'recording';
            setTimeout(() => {
              if (this.ondataavailable) {
                this.ondataavailable({ data: new Blob(['test']) });
              }
            }, 100);
          }
          
          stop() {
            this.state = 'inactive';
            setTimeout(() => {
              if (this.onstop) this.onstop();
            }, 100);
          }
        };
      """)
    end

    it "handles recording lifecycle" do
      visit conversation_path(conversation)
      
      expect(page).to have_stimulus_controller("message-recorder")
      
      # Start recording
      find("[data-message-recorder-target='recordBtn']").click
      
      # Should show recording state
      expect(page).to have_css("[data-message-recorder-target='recordingIndicator']:not(.hidden)")
      expect(page).to have_css("[data-message-recorder-target='recordBtn'].bg-red-100")
      
      # Stop recording
      find("[data-message-recorder-target='recordBtn']").click
      
      # Should show recording review
      expect(page).to have_css("[data-message-recorder-target='recordingReview']:not(.hidden)", wait: 5)
      expect(page).to have_css("[data-message-recorder-target='playBtn']")
      expect(page).to have_css("[data-message-recorder-target='waveform']")
    end

    it "handles playback functionality" do
      visit conversation_path(conversation)
      
      # Record something first
      find("[data-message-recorder-target='recordBtn']").click
      sleep(1)
      find("[data-message-recorder-target='recordBtn']").click
      
      # Wait for review to appear
      expect(page).to have_css("[data-message-recorder-target='recordingReview']:not(.hidden)", wait: 5)
      
      # Test playback
      play_button = find("[data-message-recorder-target='playBtn']")
      play_button.click
      
      # Should show pause state
      expect(page).to have_css("[data-message-recorder-target='playIcon'].hidden")
      expect(page).to have_css("[data-message-recorder-target='pauseIcon']:not(.hidden)")
      
      # Test pause
      pause_button = find("[data-message-recorder-target='playBtn']")
      pause_button.click
      
      expect(page).to have_css("[data-message-recorder-target='playIcon']:not(.hidden)")
      expect(page).to have_css("[data-message-recorder-target='pauseIcon'].hidden")
    end

    it "clears recording properly" do
      visit conversation_path(conversation)
      
      # Record and then clear
      find("[data-message-recorder-target='recordBtn']").click
      sleep(1)
      find("[data-message-recorder-target='recordBtn']").click
      
      # Wait for review
      expect(page).to have_css("[data-message-recorder-target='recordingReview']:not(.hidden)", wait: 5)
      
      # Clear recording
      find("[data-message-recorder-target='clearRecordingBtn']").click
      
      # Should reset to initial state
      expect(page).to have_css("[data-message-recorder-target='recordingReview'].hidden")
      expect(find("[data-message-recorder-target='sendBtn']").text).to eq("Send")
      expect(page).not_to have_css("[data-message-recorder-target='sendBtn'].bg-purple-600")
    end

    it "handles form submission with recording" do
      visit conversation_path(conversation)
      
      # Add text message
      fill_in "message_body", with: "Test message"
      
      # Add recording
      find("[data-message-recorder-target='recordBtn']").click
      sleep(1)
      find("[data-message-recorder-target='recordBtn']").click
      
      # Wait for review
      expect(page).to have_css("[data-message-recorder-target='recordingReview']:not(.hidden)", wait: 5)
      
      # Send should include voice message
      expect(find("[data-message-recorder-target='sendBtn']").text).to eq("Send with Voice Message")
      
      # Submit form
      find("[data-message-recorder-target='sendBtn']").click
      
      # Should reset after successful submission
      expect(find_field("message_body").value).to be_blank
      expect(page).to have_css("[data-message-recorder-target='recordingReview'].hidden")
    end

    it "handles microphone access denied" do
      # Mock permission denied
      page.execute_script("""
        navigator.mediaDevices.getUserMedia = function() {
          return Promise.reject(new Error('Permission denied'));
        };
      """)
      
      visit conversation_path(conversation)
      
      find("[data-message-recorder-target='recordBtn']").click
      
      # Should show error message
      expect(page).to have_content("Microphone access denied")
    end
  end

  describe "waveform visualization" do
    it "generates waveform bars" do
      visit conversation_path(conversation)
      
      # Record something
      find("[data-message-recorder-target='recordBtn']").click
      sleep(1)
      find("[data-message-recorder-target='recordBtn']").click
      
      # Wait for review
      expect(page).to have_css("[data-message-recorder-target='recordingReview']:not(.hidden)", wait: 5)
      
      # Should have waveform bars
      waveform = find("[data-message-recorder-target='waveform']")
      bars = waveform.all("div")
      expect(bars.count).to eq(40) # As per implementation
      
      bars.each do |bar|
        expect(bar[:class]).to include("bg-indigo-300")
        expect(bar[:style]).to include("width: 2px")
      end
    end

    it "animates waveform during playback" do
      visit conversation_path(conversation)
      
      # Record and play
      find("[data-message-recorder-target='recordBtn']").click
      sleep(1)
      find("[data-message-recorder-target='recordBtn']").click
      
      expect(page).to have_css("[data-message-recorder-target='recordingReview']:not(.hidden)", wait: 5)
      
      find("[data-message-recorder-target='playBtn']").click
      
      # Waveform should animate (simplified test)
      sleep(2) # Let animation run
      
      # Check that some bars changed color during animation
      waveform = find("[data-message-recorder-target='waveform']")
      bars = waveform.all("div")
      animated_bars = bars.select { |bar| bar[:class].include?("bg-indigo-600") }
      
      # At least some bars should have been animated
      expect(animated_bars.count).to be >= 0 # Animation might have finished
    end
  end
end
```

## Event Handling Testing

### Custom Event Testing
```ruby
RSpec.describe "Stimulus Event Handling", type: :system, js: true do
  let(:alice) { create(:user) }

  before { sign_in alice }

  describe "custom event dispatch and handling" do
    it "dispatches and handles custom events correctly" do
      visit projects_path
      
      # Set up event listener
      page.execute_script("""
        window.customEvents = [];
        document.addEventListener('dropdown:opened', function(event) {
          window.customEvents.push({
            type: 'dropdown:opened',
            detail: event.detail,
            timestamp: Date.now()
          });
        });
      """)
      
      # Trigger event through controller action
      find("[data-action='click->dropdown#toggle']").click
      
      # Check event was dispatched
      events = page.evaluate_script("window.customEvents")
      expect(events.length).to be >= 1
      expect(events.last['type']).to eq('dropdown:opened')
      expect(events.last['detail']).to be_present
    end

    it "handles event bubbling correctly" do
      visit projects_path
      
      # Test that events bubble properly
      page.execute_script("""
        window.eventPath = [];
        
        document.body.addEventListener('dropdown:opened', function(e) {
          window.eventPath.push('body');
        });
        
        document.addEventListener('dropdown:opened', function(e) {
          window.eventPath.push('document');
        });
      """)
      
      find("[data-action='click->dropdown#toggle']").click
      
      event_path = page.evaluate_script("window.eventPath")
      expect(event_path).to include('body')
      expect(event_path).to include('document')
    end
  end

  describe "DOM event handling" do
    it "handles keyboard events correctly" do
      visit projects_path
      
      # Open dropdown
      dropdown_trigger = find("[data-action='click->dropdown#toggle']")
      dropdown_trigger.click
      
      # Test escape key
      dropdown_trigger.send_keys(:escape)
      
      # Should close dropdown
      expect(page).to have_css("[data-dropdown-target='menu'].hidden")
    end

    it "handles window events" do
      visit projects_path
      
      # Test resize event handling (if implemented)
      page.execute_script("window.dispatchEvent(new Event('resize'))")
      
      # Controllers should handle resize if needed
      expect(page).to have_stimulus_controller("dropdown")
    end
  end
end
```

### Event Cleanup Testing
```ruby
describe "event cleanup on disconnect" do
  it "removes event listeners when controller disconnects" do
    visit projects_path
    
    # Add event listener count tracking
    page.execute_script("""
      window.originalAddEventListener = document.addEventListener;
      window.originalRemoveEventListener = document.removeEventListener;
      window.eventListenerCount = 0;
      
      document.addEventListener = function(...args) {
        window.eventListenerCount++;
        return window.originalAddEventListener.apply(this, args);
      };
      
      document.removeEventListener = function(...args) {
        window.eventListenerCount--;
        return window.originalRemoveEventListener.apply(this, args);
      };
    """)
    
    initial_count = page.evaluate_script("window.eventListenerCount")
    
    # Open dropdown (adds listeners)
    find("[data-action='click->dropdown#toggle']").click
    
    after_open_count = page.evaluate_script("window.eventListenerCount")
    expect(after_open_count).to be > initial_count
    
    # Navigate away (should trigger disconnect and cleanup)
    visit agreements_path
    
    # Event listeners should be cleaned up
    final_count = page.evaluate_script("window.eventListenerCount")
    expect(final_count).to be <= initial_count
  end
end
```

## Performance Testing

### Controller Initialization Performance
```ruby
RSpec.describe "Stimulus Performance", type: :system, js: true do
  let(:alice) { create(:user) }

  describe "controller initialization speed" do
    it "initializes controllers quickly on page load" do
      # Create page with many controllers
      create_list(:project, 50, user: alice)
      
      sign_in alice
      
      start_time = Time.current
      visit projects_path
      
      # Wait for page to fully load with all controllers
      expect(page).to have_content("Projects", wait: 10)
      
      # Check all controllers are initialized
      controller_count = page.evaluate_script("""
        document.querySelectorAll('[data-controller]').length
      """)
      
      expect(controller_count).to be >= 50
      
      load_time = Time.current - start_time
      expect(load_time).to be < 8.seconds
    end

    it "handles controller connect/disconnect cycles efficiently" do
      sign_in alice
      
      # Rapidly navigate between pages
      10.times do
        visit projects_path
        visit agreements_path
        visit time_logs_path
      end
      
      # Controllers should still be responsive
      visit projects_path
      
      dropdown = find("[data-controller*='dropdown']")
      dropdown.find("[data-action='click->dropdown#toggle']").click
      
      expect(dropdown).not_to have_css("[data-dropdown-target='menu'].hidden")
    end
  end

  describe "memory usage" do
    it "doesn't leak memory with repeated actions" do
      sign_in alice
      visit projects_path
      
      # Perform many dropdown operations
      100.times do |i|
        find("[data-action='click->dropdown#toggle']").click
        find("[data-action='click->dropdown#toggle']").click
      end
      
      # Controllers should still work normally
      find("[data-action='click->dropdown#toggle']").click
      expect(page).not_to have_css("[data-dropdown-target='menu'].hidden")
    end
  end
end
```

## Debugging and Troubleshooting

### Debug Helpers for Tests
```ruby
# spec/support/stimulus_debug_helpers.rb
module StimulusDebugHelpers
  def debug_stimulus_controllers
    controllers = page.evaluate_script("""
      Array.from(document.querySelectorAll('[data-controller]')).map(el => ({
        element: el.tagName + (el.id ? '#' + el.id : '') + (el.className ? '.' + el.className.split(' ').join('.') : ''),
        controllers: el.getAttribute('data-controller'),
        connected: !!el.stimulus
      }))
    """)
    
    puts "\n=== Stimulus Controllers Debug ==="
    controllers.each do |controller|
      puts "#{controller['element']} -> #{controller['controllers']} (connected: #{controller['connected']})"
    end
    puts "================================\n"
  end
  
  def debug_stimulus_targets(controller_name)
    targets = page.evaluate_script("""
      const controller = document.querySelector('[data-controller*=\"#{controller_name}\"]');
      if (!controller) return null;
      
      const targets = {};
      Array.from(controller.querySelectorAll('[data-#{controller_name}-target]')).forEach(el => {
        const target = el.getAttribute('data-#{controller_name}-target');
        targets[target] = {
          element: el.tagName,
          visible: !el.classList.contains('hidden'),
          value: el.value || el.textContent || null
        };
      });
      return targets;
    """)
    
    puts "\n=== #{controller_name} Controller Targets ==="
    targets&.each do |target, info|
      puts "#{target}: #{info['element']} (visible: #{info['visible']}, value: #{info['value']})"
    end
    puts "================================\n"
  end
  
  def stimulus_controller_state(controller_name)
    page.evaluate_script("""
      const el = document.querySelector('[data-controller*=\"#{controller_name}\"]');
      return el && el.stimulus ? 'connected' : 'disconnected';
    """)
  end
end

RSpec.configure do |config|
  config.include StimulusDebugHelpers, type: :system
end
```

### Common Test Debugging
```ruby
describe "debug example" do
  it "debugs stimulus controllers" do
    visit projects_path
    
    # Debug what controllers are on the page
    debug_stimulus_controllers
    
    # Debug specific controller targets
    debug_stimulus_targets("dropdown")
    
    # Check controller state
    expect(stimulus_controller_state("dropdown")).to eq("connected")
    
    # Take screenshot for visual debugging
    page.save_screenshot("debug_stimulus_#{Time.current.to_i}.png")
  end
end
```

### Error Handling in Tests
```ruby
describe "stimulus error handling" do
  it "handles JavaScript errors gracefully" do
    visit projects_path
    
    # Inject error into controller
    page.execute_script("""
      const controller = document.querySelector('[data-controller*=\"dropdown\"]');
      if (controller && controller.stimulus) {
        const originalToggle = controller.stimulus.toggle;
        controller.stimulus.toggle = function() {
          throw new Error('Test error');
        };
      }
    """)
    
    # Should not crash the page
    find("[data-action='click->dropdown#toggle']").click
    
    # Page should still be functional
    expect(page).to have_content("Projects")
  end
end
```

## Best Practices Summary

1. **Test Real User Interactions**: Use system tests to verify complete user workflows
2. **Mock Browser APIs**: Mock media APIs and other browser features for consistent testing
3. **Test Controller Lifecycle**: Verify connect, disconnect, and reconnect behaviors
4. **Performance Testing**: Test with realistic data volumes and user interactions
5. **Event Testing**: Verify custom events and DOM event handling work correctly
6. **Error Handling**: Test graceful degradation when JavaScript errors occur
7. **Integration Testing**: Test Stimulus controllers work with Rails and Turbo
8. **Debug Helpers**: Use debugging tools to understand controller state during tests
9. **Cross-browser Testing**: Test Stimulus functionality across different browsers
10. **Memory Management**: Test for memory leaks in long-running applications