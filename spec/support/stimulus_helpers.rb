# frozen_string_literal: true

# Stimulus testing helpers for Rails 8.0.2
# Provides utilities for testing Stimulus controllers and actions
module StimulusHelpers
  # Controller connection helpers
  def expect_stimulus_controller(controller_name, selector = "body")
    expect(page).to have_css("#{selector}[data-controller*='#{controller_name}']")
  end

  def expect_stimulus_target(controller_name, target_name)
    expect(page).to have_css("[data-#{controller_name}-target='#{target_name}']")
  end

  def within_stimulus_controller(controller_name, selector = "[data-controller*='#{controller_name}']")
    within(selector) do
      yield
    end
  end

  # Action triggering helpers
  def trigger_stimulus_action(controller_name, action_name, element_selector = nil)
    if element_selector
      element = find(element_selector)
    else
      element = find("[data-action*='#{controller_name}##{action_name}']")
    end

    # Determine the appropriate event type based on element
    case element.tag_name.downcase
    when 'button', 'input'
      element.click
    when 'form'
      element.trigger('submit')
    when 'select'
      # For select elements, trigger change event
      element.trigger('change')
    else
      element.click
    end
  end

  def click_stimulus_action(controller_name, action_name)
    find("[data-action*='#{controller_name}##{action_name}']").click
  end

  def submit_stimulus_form(controller_name, action_name = 'submit')
    form = find("form[data-action*='#{controller_name}##{action_name}']")
    form.trigger('submit')
  end

  # Value and class testing helpers
  def expect_stimulus_value(controller_name, value_name, expected_value)
    expect(page).to have_css("[data-#{controller_name}-#{value_name}-value='#{expected_value}']")
  end

  def expect_stimulus_class(controller_name, class_name, expected_class)
    expect(page).to have_css("[data-#{controller_name}-#{class_name}-class='#{expected_class}']")
  end

  def get_stimulus_value(controller_name, value_name)
    element = find("[data-#{controller_name}-#{value_name}-value]")
    element["data-#{controller_name}-#{value_name}-value"]
  end

  # DOM manipulation helpers
  def expect_element_added_by_stimulus(selector)
    expect(page).to have_css(selector)
  end

  def expect_element_removed_by_stimulus(selector)
    expect(page).not_to have_css(selector)
  end

  def expect_class_added_by_stimulus(selector, css_class)
    expect(page).to have_css("#{selector}.#{css_class}")
  end

  def expect_class_removed_by_stimulus(selector, css_class)
    expect(page).not_to have_css("#{selector}.#{css_class}")
  end

  # Common Stimulus patterns
  def expect_modal_controller(modal_selector = "[data-controller*='modal']")
    expect_stimulus_controller('modal', modal_selector)
    within_stimulus_controller('modal', modal_selector) do
      expect(page).to have_css("[data-modal-target]")
    end
  end

  def expect_dropdown_controller(dropdown_selector = "[data-controller*='dropdown']")
    expect_stimulus_controller('dropdown', dropdown_selector)
  end

  def expect_form_controller(form_selector = "form[data-controller]")
    controller_attr = find(form_selector)['data-controller']
    expect(controller_attr).to be_present
  end

  # Auto-complete and search helpers
  def expect_search_controller(search_input_selector = "[data-controller*='search']")
    expect_stimulus_controller('search', search_input_selector)
  end

  def trigger_search_input(query, search_input_selector = "[data-action*='search']")
    fill_in_stimulus_target('search', 'input', with: query)
    # Trigger the search action (usually on input or keyup)
    find(search_input_selector).send_keys(:tab) # Trigger blur to ensure action fires
  end

  def fill_in_stimulus_target(controller_name, target_name, with:)
    fill_in find("[data-#{controller_name}-target='#{target_name}']")['id'], with:
  end

  # Toggle and state helpers
  def expect_toggle_controller(toggle_selector = "[data-controller*='toggle']")
    expect_stimulus_controller('toggle', toggle_selector)
  end

  def toggle_stimulus_element(controller_name = 'toggle', action_name = 'toggle')
    trigger_stimulus_action(controller_name, action_name)
  end

  def expect_element_toggled(selector)
    # Check for common toggle states
    element = find(selector)
    expect(element['aria-expanded']).to be_present.or(
      expect(element).to have_css('.hidden').or(be_visible)
    )
  end

  # AJAX and remote form helpers
  def expect_remote_form_controller(form_selector = "form[data-controller*='remote-form']")
    expect_stimulus_controller('remote-form', form_selector)
  end

  def submit_remote_stimulus_form(form_selector = "form[data-controller*='remote-form']")
    within(form_selector) do
      click_button 'submit', match: :first
    end
  end

  # Loading and async helpers
  def expect_loading_controller(element_selector = "[data-controller*='loading']")
    expect_stimulus_controller('loading', element_selector)
  end

  def expect_stimulus_loading_state(controller_name = 'loading')
    expect_stimulus_class(controller_name, 'loading', 'opacity-50') # or whatever loading class is used
  end

  def wait_for_stimulus_action_complete(timeout: 5)
    # Wait for any loading states to complete
    expect(page).to have_no_css("[aria-busy='true'], .loading", wait: timeout)
  end

  # Custom event helpers
  def trigger_custom_stimulus_event(event_name, element_selector = "body")
    page.execute_script(<<~JS)
      const element = document.querySelector('#{element_selector}');
      const event = new CustomEvent('#{event_name}', {#{' '}
        bubbles: true,#{' '}
        detail: { testing: true }#{' '}
      });
      element.dispatchEvent(event);
    JS
  end

  # Debug helpers for testing
  def debug_stimulus_controllers
    controllers = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('[data-controller]')).map(el => ({
        element: el.tagName,
        controllers: el.dataset.controller,
        targets: Object.keys(el.dataset).filter(key => key.includes('Target')),
        values: Object.keys(el.dataset).filter(key => key.includes('Value'))
      }))
    JS
    puts "Stimulus Controllers Found:"
    controllers.each { |ctrl| puts "  #{ctrl}" }
  end

  # Animation and transition helpers
  def expect_css_transition_complete(selector, property = 'opacity', timeout: 2)
    # Wait for CSS transitions to complete
    expect(page).to have_css(selector, wait: timeout)

    # Give time for transition to complete
    sleep 0.1 if page.evaluate_script(<<~JS)
      const element = document.querySelector('#{selector}');
      const computed = window.getComputedStyle(element);
      computed.transitionDuration !== '0s' || computed.animationDuration !== '0s';
    JS
  end
end

RSpec.configure do |config|
  config.include StimulusHelpers, type: :system
  config.include StimulusHelpers, type: :feature
end
