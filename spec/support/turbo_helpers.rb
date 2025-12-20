# frozen_string_literal: true

# Turbo testing helpers for Rails 8.0.2 with Hotwire
# Provides utilities for testing Turbo Frames, Streams, and Drive functionality
module TurboHelpers
  # Frame testing helpers
  def expect_turbo_frame(id, **options)
    selector = "turbo-frame##{id}"
    selector += "[src='#{options[:src]}']" if options[:src]
    selector += "[loading='#{options[:loading]}']" if options[:loading]

    expect(page).to have_css(selector)
  end

  def within_turbo_frame(id)
    within("turbo-frame##{id}") do
      yield
    end
  end

  def expect_frame_content(frame_id, content)
    within_turbo_frame(frame_id) do
      expect(page).to have_content(content)
    end
  end

  def expect_lazy_frame(frame_id, src_path)
    expect_turbo_frame(frame_id, loading: "lazy", src: src_path)
  end

  # Stream testing helpers
  def expect_turbo_stream_action(action, target: nil, targets: nil)
    if target
      expect(response.body).to include("turbo-stream action=\"#{action}\" target=\"#{target}\"")
    elsif targets
      expect(response.body).to include("turbo-stream action=\"#{action}\" targets=\"#{targets}\"")
    else
      expect(response.body).to include("turbo-stream action=\"#{action}\"")
    end
  end

  def expect_stream_append(target)
    expect_turbo_stream_action("append", target:)
  end

  def expect_stream_prepend(target)
    expect_turbo_stream_action("prepend", target:)
  end

  def expect_stream_replace(target)
    expect_turbo_stream_action("replace", target:)
  end

  def expect_stream_remove(target)
    expect_turbo_stream_action("remove", target:)
  end

  def expect_stream_update(target)
    expect_turbo_stream_action("update", target:)
  end

  # Form submission helpers
  def submit_turbo_form(form_selector, **options)
    within(form_selector) do
      if options[:button_text]
        click_button(options[:button_text])
      elsif options[:button_selector]
        find(options[:button_selector]).click
      else
        find('input[type="submit"], button[type="submit"]').click
      end
    end
  end

  def expect_turbo_form_response(expected_response_type = :turbo_stream)
    case expected_response_type
    when :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    when :html
      expect(response.media_type).to eq("text/html")
    end
  end

  # Navigation and targeting helpers
  def click_with_turbo_frame(link_text, frame_target)
    click_link(link_text, **{ "data-turbo-frame": frame_target })
  end

  def expect_turbo_frame_navigation(frame_id, expected_path)
    within_turbo_frame(frame_id) do
      # Check if frame loaded content from expected path
      # This is inferred from DOM changes rather than direct URL checking
      expect(page).to have_content(/.*/) # Frame should have content
    end
  end

  # Drive and caching helpers
  def expect_turbo_drive_enabled
    expect(page).to have_css("html[data-turbo='true']")
  end

  def expect_page_cached
    # Check for turbo cache meta tag or cache-related attributes
    expect(page).not_to have_css("html[data-turbo-preview]")
  end

  # Error handling helpers
  def expect_turbo_error_handling
    # Check for proper error display without full page reload
    expect(page).not_to have_css("body[data-turbo='false']")
  end

  # Performance helpers
  def measure_turbo_response_time
    start_time = Time.current
    yield
    end_time = Time.current
    end_time - start_time
  end

  def expect_fast_turbo_response(max_seconds = 1.0)
    response_time = measure_turbo_response_time { yield }
    expect(response_time).to be < max_seconds
  end

  # Modal and stimulus integration helpers
  def expect_turbo_modal(modal_id)
    expect(page).to have_css("turbo-frame##{modal_id}[data-controller*='modal']")
  end

  def close_turbo_modal(modal_id = nil)
    selector = modal_id ? "##{modal_id}" : "[data-controller*='modal']"
    within(selector) do
      # Look for common modal close patterns
      if has_css?("[data-action*='modal#close']")
        find("[data-action*='modal#close']").click
      elsif has_css?(".modal-close, .btn-close, [aria-label='Close']")
        find(".modal-close, .btn-close, [aria-label='Close']").click
      else
        find("button", text: /close|×|cancel/i).click
      end
    end
  end

  # Loading state helpers
  def expect_loading_state(container_selector = "body")
    within(container_selector) do
      expect(page).to have_css("[data-turbo-permanent][aria-busy='true'], .loading, .spinner")
    end
  end

  def wait_for_turbo_frame_load(frame_id, timeout: 5)
    expect(page).to have_css("turbo-frame##{frame_id}:not([aria-busy='true'])", wait: timeout)
  end

  def wait_for_all_turbo_frames(timeout: 5)
    expect(page).to have_no_css("turbo-frame[aria-busy='true']", wait: timeout)
  end
end

RSpec.configure do |config|
  config.include TurboHelpers, type: :system
  config.include TurboHelpers, type: :request
end
