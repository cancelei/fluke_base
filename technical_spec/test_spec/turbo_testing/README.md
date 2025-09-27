# Turbo Testing Patterns in FlukeBase

This document outlines comprehensive testing patterns for Turbo Frames, Turbo Streams, and real-time features, complementing the implementation patterns documented in `../hotwire_turbo/README.md`.

## Table of Contents

1. [Testing Framework Setup](#testing-framework-setup)
2. [Turbo Frame Testing](#turbo-frame-testing)
3. [Turbo Stream Testing](#turbo-stream-testing)
4. [Lazy Loading Testing](#lazy-loading-testing)
5. [Form Integration Testing](#form-integration-testing)
6. [Real-time Update Testing](#real-time-update-testing)
7. [Error Handling Testing](#error-handling-testing)
8. [Performance Testing](#performance-testing)

## Testing Framework Setup

### Capybara Configuration for Turbo
**Reference**: `../hotwire_turbo/README.md` - Complete Hotwire Turbo implementation

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:each, type: :system) do |example|
    if example.metadata[:js]
      driven_by :selenium_chrome_headless
    else
      driven_by :rack_test
    end
  end
end

# Turbo-specific configuration
Capybara.configure do |config|
  config.default_wait_time = 5
  config.server = :puma, { Silent: true }
end

# Custom matchers for Turbo
RSpec::Matchers.define :have_turbo_frame do |frame_id|
  match do |page|
    page.has_css?("turbo-frame[id='#{frame_id}']")
  end
  
  failure_message do |page|
    "expected page to have turbo-frame with id '#{frame_id}'"
  end
end

RSpec::Matchers.define :have_received_turbo_stream do |action, target|
  match do |response|
    response.body.include?("turbo-stream action=\"#{action}\" target=\"#{target}\"")
  end
  
  failure_message do |response|
    "expected response to contain turbo-stream with action '#{action}' targeting '#{target}'"
  end
end
```

## Turbo Frame Testing

### Basic Turbo Frame Testing
**Reference**: `../hotwire_turbo/README.md` - Turbo Frames section

```ruby
RSpec.describe "Agreement Turbo Frames", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  before { sign_in alice }

  describe "agreement results frame" do
    it "loads independently without full page refresh" do
      visit agreements_path
      
      expect(page).to have_turbo_frame("agreement_results")
      expect(page).to have_content(project.name)
      
      # Verify frame loads content
      within("turbo-frame#agreement_results") do
        expect(page).to have_content("Your Projects")
        expect(page).to have_content("Your Mentorships")
      end
    end

    it "handles nested frames correctly" do
      visit agreements_path
      
      # Check nested frames exist
      expect(page).to have_turbo_frame("agreements_my")
      expect(page).to have_turbo_frame("agreements_other")
      
      # Verify nested content
      within("turbo-frame#agreements_my") do
        expect(page).to have_content(agreement.project.name)
      end
    end
  end

  describe "frame updates" do
    it "updates frame content via form submission" do
      visit agreements_path
      
      # Submit filter form
      select "Pending", from: "Status"
      
      # Verify frame updates without page reload
      expect(page).not_to have_selector(".page-loading")
      expect(page).to have_turbo_frame("agreement_results")
      
      # Check that URL doesn't change (frame update, not navigation)
      expect(current_path).to eq(agreements_path)
    end
  end
end
```

### Agreement Show Frame Testing
**Reference**: `../hotwire_turbo/README.md` - Show Page Turbo Frame Structure

```ruby
RSpec.describe "Agreement Show Turbo Frames", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  before { sign_in alice }

  describe "main agreement frame" do
    it "renders agreement in turbo frame" do
      visit agreement_path(agreement)
      
      expect(page).to have_turbo_frame("agreement_#{agreement.id}")
      
      within("turbo-frame#agreement_#{agreement.id}") do
        expect(page).to have_content(agreement.project.name)
        expect(page).to have_content(agreement.status.titleize)
      end
    end

    it "handles status updates via turbo streams" do
      visit agreement_path(agreement)
      
      # Bob accepts the agreement
      within("turbo-frame#agreement_#{agreement.id}") do
        expect(page).to have_button("Accept")
      end
      
      sign_in bob
      visit agreement_path(agreement)
      click_button "Accept"
      
      # Verify frame updates with new status
      expect(page).to have_content("Accepted")
      expect(page).not_to have_button("Accept")
    end
  end
end
```

### Frame Error Testing
```ruby
describe "frame error handling" do
  it "shows error state when frame fails to load" do
    # Simulate server error
    allow_any_instance_of(AgreementsController).to receive(:show).and_raise(StandardError)
    
    visit agreement_path(agreement)
    
    # Should show error within frame, not crash entire page
    expect(page).to have_content("Unable to load agreement details")
    expect(page).not_to have_content("We're sorry, but something went wrong")
  end
end
```

## Turbo Stream Testing

### Controller Turbo Stream Testing
**Reference**: `../hotwire_turbo/README.md` - Turbo Streams section

```ruby
RSpec.describe AgreementsController, type: :controller do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  describe "POST #accept with turbo_stream format" do
    before { sign_in bob }

    it "returns multiple stream updates" do
      post :accept, params: { id: agreement.id }, format: :turbo_stream
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      
      # Check for multiple stream actions
      expect(response).to have_received_turbo_stream("replace", "agreement_#{agreement.id}_show_status")
      expect(response).to have_received_turbo_stream("replace", "agreement_#{agreement.id}_status")
      expect(response).to have_received_turbo_stream("replace", "agreement_#{agreement.id}_actions")
      expect(response).to have_received_turbo_stream("prepend", "flash_messages")
    end

    it "handles context-aware updates" do
      post :accept, params: { id: agreement.id, context: "index" }, format: :turbo_stream
      
      # Should update index row differently than show page
      expect(response).to have_received_turbo_stream("replace", "agreement_#{agreement.id}")
      expect(response.body).to include("agreement_index_row")
    end
  end

  describe "filtering with turbo streams" do
    before { sign_in alice }

    it "updates both filters and results" do
      get :index, params: { status: "pending" }, format: :turbo_stream
      
      expect(response).to have_received_turbo_stream("update", "agreement_filters")
      expect(response).to have_received_turbo_stream("update", "agreement_results")
    end
  end
end
```

### Integration Turbo Stream Testing
```ruby
RSpec.describe "Agreement Turbo Streams", type: :request do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  describe "real-time agreement updates" do
    it "broadcasts updates to all participants" do
      sign_in bob
      
      # Accept agreement with turbo stream
      patch agreement_accept_path(agreement), 
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      expect(response).to have_http_status(:success)
      
      # Verify stream content
      stream_content = response.body
      expect(stream_content).to include('turbo-stream action="replace"')
      expect(stream_content).to include('turbo-stream action="prepend"')
      expect(stream_content).to include("Agreement was successfully accepted")
      
      # Verify agreement was actually updated
      expect(agreement.reload.status).to eq("accepted")
    end

    it "handles failed updates gracefully" do
      # Try to accept already accepted agreement
      agreement.update!(status: "accepted")
      
      sign_in bob
      patch agreement_accept_path(agreement),
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Unable to accept agreement")
      expect(response.body).to include('target="flash_messages"')
    end
  end
end
```

### System-Level Stream Testing
```ruby
RSpec.describe "Turbo Stream System Tests", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  it "updates multiple parts of page simultaneously" do
    sign_in bob
    visit agreement_path(agreement)
    
    # Click accept button
    click_button "Accept"
    
    # Wait for turbo stream updates
    expect(page).to have_content("Agreement was successfully accepted", wait: 5)
    
    # Verify multiple elements updated
    expect(page).to have_content("Status: Accepted")
    expect(page).not_to have_button("Accept")
    expect(page).not_to have_button("Reject")
    expect(page).to have_button("Complete") # New action available
    
    # Verify flash message appears and is dismissible
    within("#flash_messages") do
      expect(page).to have_content("Agreement was successfully accepted")
      find("button[type='button']").click # Close button
    end
    
    expect(page).not_to have_content("Agreement was successfully accepted")
  end

  it "handles multiple simultaneous updates" do
    sign_in alice
    visit agreements_path
    
    # Apply multiple filters quickly
    select "Mentorship", from: "Agreement Type"
    select "Pending", from: "Status"
    
    # Should handle both updates without conflicts
    expect(page).to have_content("2 filters active")
    expect(page).to have_link("Clear all filters")
  end
end
```

## Lazy Loading Testing

### Lazy Frame Loading Testing
**Reference**: `../hotwire_turbo/README.md` - Lazy Loading Patterns

```ruby
RSpec.describe "Lazy Loading Turbo Frames", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, :accepted, project: project, initiator: alice, other_party: bob) }
  let!(:meeting) { create(:meeting, agreement: agreement, user: alice) }

  before { sign_in alice }

  describe "meetings section lazy loading" do
    it "shows loading placeholder initially" do
      visit agreement_path(agreement)
      
      # Check for lazy loading frame
      expect(page).to have_turbo_frame("agreement_#{agreement.id}_meetings")
      
      # Should show loading placeholder
      within("turbo-frame#agreement_#{agreement.id}_meetings") do
        expect(page).to have_content("Loading meetings...")
        expect(page).to have_css(".animate-pulse")
      end
    end

    it "loads content when frame becomes visible" do
      visit agreement_path(agreement)
      
      # Wait for lazy loading to complete
      expect(page).to have_content(meeting.title, wait: 10)
      
      # Verify content loaded
      within("turbo-frame#agreement_#{agreement.id}_meetings") do
        expect(page).to have_content("Meetings")
        expect(page).to have_content(meeting.title)
        expect(page).not_to have_content("Loading meetings...")
      end
    end

    it "handles loading errors gracefully" do
      # Simulate error in lazy loading endpoint
      allow_any_instance_of(AgreementsController).to receive(:meetings_section).and_raise(StandardError)
      
      visit agreement_path(agreement)
      
      # Should show error state
      expect(page).to have_content("Unable to load meetings", wait: 10)
      expect(page).not_to have_css(".animate-pulse")
    end
  end

  describe "github section lazy loading" do
    it "loads github data independently" do
      visit agreement_path(agreement)
      
      # Both sections should load independently
      expect(page).to have_turbo_frame("agreement_#{agreement.id}_github")
      expect(page).to have_turbo_frame("agreement_#{agreement.id}_meetings")
      
      # Wait for both to load
      expect(page).to have_content("GitHub Integration", wait: 10)
      expect(page).to have_content("Meetings", wait: 10)
    end
  end
end
```

### Controller Lazy Loading Testing
```ruby
RSpec.describe "Lazy Loading Controllers", type: :controller do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, :accepted, project: project, initiator: alice, other_party: bob) }

  before { sign_in alice }

  describe "GET #meetings_section" do
    it "returns turbo stream for meetings frame" do
      get :meetings_section, params: { id: agreement.id }, format: :turbo_stream
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response).to have_received_turbo_stream("replace", "agreement_#{agreement.id}_meetings")
    end

    it "includes optimized queries" do
      # Create meetings with related data
      create_list(:meeting, 3, agreement: agreement, user: alice)
      
      expect {
        get :meetings_section, params: { id: agreement.id }, format: :turbo_stream
      }.not_to exceed_query_limit(5) # Should use includes to avoid N+1
    end

    it "handles errors with fallback UI" do
      allow_any_instance_of(Agreement).to receive(:meetings).and_raise(StandardError)
      
      get :meetings_section, params: { id: agreement.id }, format: :turbo_stream
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("lazy_loading_error")
    end
  end
end
```

## Form Integration Testing

### Auto-submitting Forms Testing
**Reference**: `../hotwire_turbo/README.md` - Form Integration section

```ruby
RSpec.describe "Turbo Form Integration", type: :system, js: true do
  let(:alice) { create(:user) }
  let!(:agreements) { create_list(:agreement, 5, :with_participants) }

  before { sign_in alice }

  describe "filter forms" do
    it "auto-submits on field changes" do
      visit agreements_path
      
      # Change status filter
      select "Pending", from: "Status"
      
      # Should auto-submit without clicking submit button
      expect(page).to have_content("1 filter active", wait: 5)
      expect(page).not_to have_button("Apply Filters") # Hidden button
    end

    it "debounces search input" do
      visit agreements_path
      
      search_field = find_field("Search")
      search_field.fill_in(with: "test")
      
      # Should not submit immediately
      expect(page).not_to have_content("1 filter active")
      
      # Wait for debounce delay
      sleep(0.6)
      
      # Now should have submitted
      expect(page).to have_content("1 filter active", wait: 2)
    end

    it "handles multiple rapid changes" do
      visit agreements_path
      
      # Make rapid changes
      select "Mentorship", from: "Agreement Type"
      select "Pending", from: "Status"
      fill_in "Search", with: "project"
      
      # Should end up with all filters applied
      expect(page).to have_content("3 filters active", wait: 10)
      expect(page).to have_link("Clear all filters")
    end
  end

  describe "clear filters functionality" do
    it "clears all filters with turbo request" do
      visit agreements_path
      
      # Apply filters
      select "Pending", from: "Status"
      select "Mentorship", from: "Agreement Type"
      
      expect(page).to have_content("2 filters active")
      
      # Clear filters
      click_link "Clear all filters"
      
      # Should clear and update via turbo
      expect(page).not_to have_content("filters active")
      expect(page).not_to have_link("Clear all filters")
      
      # Form should be reset
      expect(find_field("Status").value).to eq("")
      expect(find_field("Agreement Type").value).to eq("")
    end
  end
end
```

### Form Error Handling with Turbo
```ruby
RSpec.describe "Form Error Handling", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:project) { create(:project, user: alice) }

  before { sign_in alice }

  describe "agreement creation errors" do
    it "handles validation errors with turbo" do
      visit new_agreement_path(project_id: project.id, other_party_id: alice.id) # Same user error
      
      fill_in "Tasks", with: "Help with project"
      click_button "Create Agreement"
      
      # Should show errors without page refresh
      expect(page).to have_content("can't create agreement with yourself")
      expect(current_path).to eq(new_agreement_path) # Stayed on same page
      
      # Form should preserve data
      expect(find_field("Tasks").value).to eq("Help with project")
    end

    it "handles server errors gracefully" do
      # Simulate server error
      allow_any_instance_of(AgreementForm).to receive(:save).and_raise(StandardError)
      
      visit new_agreement_path(project_id: project.id)
      click_button "Create Agreement"
      
      # Should show error message
      expect(page).to have_content("Unable to create agreement")
      expect(page).not_to have_content("500 Internal Server Error")
    end
  end
end
```

## Real-time Update Testing

### WebSocket/ActionCable Testing
```ruby
RSpec.describe "Real-time Updates", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:project) { create(:project, user: alice) }
  let!(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }

  # Mock ActionCable for testing
  before do
    stub_connection
  end

  describe "agreement status changes" do
    it "updates all connected users" do
      # Alice views agreement
      using_session(:alice) do
        sign_in alice
        visit agreement_path(agreement)
        expect(page).to have_content("Status: Pending")
      end

      # Bob accepts agreement in different session
      using_session(:bob) do
        sign_in bob
        visit agreement_path(agreement)
        click_button "Accept"
        expect(page).to have_content("Status: Accepted")
      end

      # Alice should see update without refresh
      using_session(:alice) do
        expect(page).to have_content("Status: Accepted", wait: 10)
        expect(page).not_to have_button("Accept") # Actions updated too
      end
    end
  end

  private

  def stub_connection
    allow_any_instance_of(ActionCable::Connection::Base).to receive(:current_user).and_return(alice)
  end
end
```

### Background Job Integration Testing
```ruby
RSpec.describe "Background Job Turbo Updates", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:project) { create(:project, user: alice) }

  before { sign_in alice }

  describe "long-running operations" do
    it "shows progress updates via turbo streams" do
      visit project_path(project)
      
      # Trigger background job (e.g., GitHub sync)
      click_button "Sync GitHub Data"
      
      # Should show initial loading state
      expect(page).to have_content("Syncing GitHub data...")
      expect(page).to have_css(".loading-spinner")
      
      # Simulate job progress updates via turbo streams
      # (In real test, this would be handled by background job)
      
      # Should eventually show completion
      expect(page).to have_content("GitHub sync completed", wait: 30)
      expect(page).not_to have_css(".loading-spinner")
    end

    it "handles job failures gracefully" do
      # Simulate job failure
      allow_any_instance_of(GitHubSyncJob).to receive(:perform).and_raise(StandardError)
      
      visit project_path(project)
      click_button "Sync GitHub Data"
      
      expect(page).to have_content("GitHub sync failed", wait: 30)
      expect(page).to have_button("Retry Sync")
    end
  end
end
```

## Error Handling Testing

### Turbo Error Response Testing
**Reference**: `../hotwire_turbo/README.md` - Error Handling section

```ruby
RSpec.describe "Turbo Error Handling", type: :system, js: true do
  let(:alice) { create(:user) }

  before { sign_in alice }

  describe "network errors" do
    it "handles connection timeouts" do
      # Simulate slow network
      page.driver.browser.network_conditions = {
        offline: false,
        latency: 5000,
        download_throughput: 1000,
        upload_throughput: 1000
      }
      
      visit agreements_path
      select "Pending", from: "Status"
      
      # Should show loading state
      expect(page).to have_css(".turbo-progress-bar", wait: 2)
      
      # Eventually should either succeed or show error
      expect(page).to have_content("1 filter active").or have_content("Connection error")
    end

    it "handles server errors gracefully" do
      # Simulate 500 error
      allow_any_instance_of(AgreementsController).to receive(:index).and_raise(StandardError)
      
      visit agreements_path
      
      # Should show error page, not crash
      expect(page).to have_content("Something went wrong")
      expect(page).not_to have_content("Exception")
    end
  end

  describe "turbo frame errors" do
    it "shows frame-specific errors" do
      # Mock lazy loading failure
      allow_any_instance_of(AgreementsController).to receive(:meetings_section).and_return(
        head(:internal_server_error)
      )
      
      visit agreement_path(create(:agreement, :with_participants))
      
      # Should show error within frame, not break entire page
      expect(page).to have_content("Unable to load meetings")
      expect(page).to have_content("Repository access") # Other frames still work
    end
  end
end
```

### Graceful Degradation Testing
```ruby
RSpec.describe "Graceful Degradation", type: :system do
  let(:alice) { create(:user) }

  before { sign_in alice }

  describe "without JavaScript" do
    it "works with traditional form submissions", js: false do
      visit agreements_path
      
      select "Pending", from: "Status"
      click_button "Apply Filters"
      
      # Should work with full page reload
      expect(page).to have_content("1 filter active")
      expect(current_url).to include("status=pending")
    end

    it "handles agreement actions without turbo", js: false do
      agreement = create(:agreement, :with_participants)
      
      visit agreement_path(agreement)
      click_button "Accept"
      
      # Should redirect with traditional response
      expect(page).to have_content("Agreement was successfully accepted")
      expect(current_path).to eq(agreement_path(agreement))
    end
  end
end
```

## Performance Testing

### Turbo Performance Testing
```ruby
RSpec.describe "Turbo Performance", type: :system, js: true do
  let(:alice) { create(:user) }
  let(:project) { create(:project, user: alice) }

  before { sign_in alice }

  describe "large datasets" do
    it "handles many agreements efficiently" do
      # Create many agreements
      create_list(:agreement, 100, :with_participants)
      
      start_time = Time.current
      visit agreements_path
      
      # Should load within reasonable time
      expect(page).to have_content("Your Projects", wait: 10)
      load_time = Time.current - start_time
      expect(load_time).to be < 5.seconds
    end

    it "paginates large results" do
      create_list(:agreement, 50, :with_participants)
      
      visit agreements_path
      
      # Should show pagination
      expect(page).to have_css(".pagination")
      expect(page).to have_content("Next")
      
      # Pagination should use turbo
      click_link "Next"
      expect(page).to have_content("Previous")
    end
  end

  describe "frame loading performance" do
    it "loads frames concurrently" do
      agreement = create(:agreement, :with_participants, :accepted)
      create_list(:meeting, 5, agreement: agreement)
      
      start_time = Time.current
      visit agreement_path(agreement)
      
      # All lazy frames should load concurrently
      expect(page).to have_content("GitHub Integration", wait: 15)
      expect(page).to have_content("Meetings", wait: 15)
      expect(page).to have_content("Time Tracking", wait: 15)
      
      total_load_time = Time.current - start_time
      expect(total_load_time).to be < 10.seconds # Concurrent, not sequential
    end
  end

  describe "memory usage" do
    it "cleans up turbo frames properly" do
      agreement = create(:agreement, :with_participants)
      
      # Navigate between many pages
      20.times do |i|
        visit agreements_path
        visit agreement_path(agreement)
      end
      
      # Check for memory leaks (simplified)
      expect(page.driver.browser.execute_script("return window.performance.memory")).to be_present
    end
  end
end
```

## Best Practices Summary

1. **Test Frame Independence**: Verify frames load and update independently
2. **Stream Verification**: Check multiple stream actions in single responses  
3. **Lazy Loading**: Test loading states, content loading, and error handling
4. **Form Integration**: Verify auto-submit, debouncing, and error handling
5. **Real-time Updates**: Test WebSocket connections and background job integration
6. **Error Handling**: Test network errors, server errors, and graceful degradation
7. **Performance**: Test with large datasets and concurrent operations
8. **Progressive Enhancement**: Ensure functionality works without JavaScript
9. **User Experience**: Test loading states, transitions, and feedback
10. **Cross-browser**: Test Turbo functionality across different browsers

## Testing Tools and Utilities

### Custom Test Helpers
```ruby
# spec/support/turbo_helpers.rb
module TurboHelpers
  def wait_for_turbo_frame(frame_id, timeout: 10)
    expect(page).to have_turbo_frame(frame_id, wait: timeout)
  end
  
  def expect_turbo_stream_update(target)
    expect(response).to have_received_turbo_stream("update", target)
  end
  
  def within_turbo_frame(frame_id, &block)
    within("turbo-frame##{frame_id}", &block)
  end
  
  def simulate_turbo_visit(path)
    page.execute_script("Turbo.visit('#{path}')")
  end
end

RSpec.configure do |config|
  config.include TurboHelpers, type: :system
  config.include TurboHelpers, type: :request
end
```

### Debugging Turbo in Tests
```ruby
# Add to test when debugging
puts response.body # See turbo stream content
page.save_screenshot # Visual debugging
puts page.html # Current page state
page.execute_script("console.log(Turbo)") # Turbo state
```