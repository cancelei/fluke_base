# frozen_string_literal: true

# Accessibility testing helpers for Rails 8.0.2
# Provides utilities for comprehensive accessibility testing across views and components
module AccessibilityHelpers
  # Semantic HTML structure testing
  def expect_semantic_html
    # Check for proper document structure
    expect(rendered).to have_css('h1, h2, h3, h4, h5, h6', minimum: 1) # Heading hierarchy
  end

  def expect_heading_hierarchy
    headings = page.all('h1, h2, h3, h4, h5, h6').map(&:tag_name)

    # Should start with h1
    expect(headings.first).to eq('H1') if headings.any?

    # Check for logical progression (no skipping levels)
    heading_levels = headings.map { |h| h[1].to_i }.each_cons(2)
    heading_levels.each do |current, next_heading|
      expect(next_heading - current).to be <= 1
    end
  end

  def expect_landmark_elements
    # Should have main landmarks
    expect(page).to have_css('main, [role="main"]').or(
      have_css('section, article')
    )
  end

  # Image accessibility
  def expect_accessible_images
    # All images should have alt text
    images_without_alt = page.all('img:not([alt])')
    expect(images_without_alt).to be_empty,
      "Found #{images_without_alt.size} images without alt attributes"

    # Decorative images should have empty alt
    decorative_images = page.all('img[alt=""]')
    decorative_images.each do |img|
      # Decorative images should not have informational context
      expect(img[:title]).to be_blank
    end
  end

  def expect_meaningful_alt_text
    informational_images = page.all('img[alt]:not([alt=""])')
    informational_images.each do |img|
      alt_text = img[:alt]
      expect(alt_text.length).to be > 2 # Meaningful description
      expect(alt_text).not_to match(/\.(jpg|png|gif|svg)$/i) # Not just filename
      expect(alt_text).not_to match(/^(image|picture|photo)$/i) # Not generic
    end
  end

  # Form accessibility
  def expect_accessible_forms
    # All form inputs should have labels or aria-label
    unlabeled_inputs = page.all('input:not([aria-label]):not([aria-labelledby]):not([id])')
    unlabeled_inputs.each do |input|
      input_id = input[:id]
      expect(page).to have_css("label[for='#{input_id}']") if input_id.present?
    end

    # Required fields should be indicated
    required_fields = page.all('input[required], select[required], textarea[required]')
    required_fields.each do |field|
      # Should have aria-required or visual indicator
      expect(field['aria-required']).to eq('true').or(
        expect(page).to have_content('*').or(have_content('required'))
      )
    end
  end

  def expect_form_validation_accessibility
    # Error messages should be associated with fields
    error_fields = page.all('[aria-invalid="true"]')
    error_fields.each do |field|
      error_id = field['aria-describedby']
      if error_id.present?
        expect(page).to have_css("##{error_id}")
      end
    end

    # Error messages should be announced
    error_messages = page.all('.error, .field_with_errors, [role="alert"]')
    expect(error_messages).to be_present if page.has_css?('[aria-invalid="true"]')
  end

  # Interactive element accessibility
  def expect_accessible_links
    # Links should have accessible text or aria-label
    empty_links = page.all('a:empty:not([aria-label]):not([title])')
    expect(empty_links).to be_empty

    # External links should indicate they open in new window
    external_links = page.all('a[target="_blank"]')
    external_links.each do |link|
      expect(link).to have_css('svg, .icon').or(
        have_text(/opens in new|external/i)
      ).or(
        have_attribute('aria-label', /new window|external/i)
      )
    end
  end

  def expect_accessible_buttons
    # Buttons should have accessible text or aria-label
    empty_buttons = page.all('button:empty:not([aria-label]):not([title])')
    expect(empty_buttons).to be_empty

    # Icon buttons should have labels
    icon_buttons = page.all('button svg, button .icon').map(&:find).map(&:first).compact
    icon_buttons.each do |button|
      expect(button).to have_attribute('aria-label').or(
        have_attribute('title')
      ).or(
        have_text(/\w+/) # Has visible text
      )
    end
  end

  # Color and contrast
  def expect_sufficient_color_contrast
    # Check for common low-contrast patterns
    low_contrast_patterns = [
      '.text-gray-300', '.text-gray-400', '.text-yellow-300'
    ]

    low_contrast_patterns.each do |pattern|
      if page.has_css?(pattern)
        # Should not be used for primary content
        primary_content = page.all("#{pattern} h1, #{pattern} h2, #{pattern} p, #{pattern} a")
        expect(primary_content).to be_empty,
          "Found primary content with potentially low contrast: #{pattern}"
      end
    end
  end

  def expect_no_color_only_information
    # Important information should not rely solely on color
    status_elements = page.all('.text-red-500, .text-green-500, .text-yellow-500, .text-blue-500')
    status_elements.each do |element|
      # Should have text, icon, or other indicator besides color
      expect(element).to have_text(/\w+/).or(
        have_css('svg, .icon')
      ).or(
        have_attribute('aria-label')
      )
    end
  end

  # Keyboard navigation
  def expect_keyboard_navigable
    # Interactive elements should be focusable
    interactive_elements = page.all('a, button, input, select, textarea, [role="button"], [role="link"]')
    interactive_elements.each do |element|
      # Should not have tabindex="-1" unless it's intentionally not focusable
      expect(element[:tabindex]).not_to eq('-1') unless element.matches?('[aria-hidden="true"]')
    end
  end

  def expect_focus_indicators
    # Should have focus styles (checking for common patterns)
    focusable_elements = page.all('a, button, input, select, textarea')
    focusable_elements.each do |element|
      classes = element[:class] || ''
      # Should have focus styles in classes
      expect(classes).to match(/focus:/).or(
        match(/:focus/)
      ).or(
        # Or have default browser focus (not outline-none without replacement)
        expect(classes).not_to match(/outline-none/)
      )
    end
  end

  # ARIA attributes
  def expect_proper_aria_usage
    # aria-hidden elements should not contain focusable content
    hidden_elements = page.all('[aria-hidden="true"]')
    hidden_elements.each do |element|
      focusable_children = element.all('a, button, input, select, textarea, [tabindex]')
      expect(focusable_children).to be_empty
    end

    # aria-expanded should be on interactive elements
    expandable_elements = page.all('[aria-expanded]')
    expandable_elements.each do |element|
      expect(element.tag_name.downcase).to be_in([ 'button', 'a' ]).or(
        expect(element).to have_attribute('role', /button|link/)
      )
    end
  end

  def expect_live_regions_when_needed
    # Dynamic content updates should use live regions
    if page.has_css?('[data-turbo-stream], .flash, .alert, .notification')
      expect(page).to have_css('[role="alert"], [role="status"], [aria-live]')
    end
  end

  # Screen reader support
  def expect_screen_reader_content
    # Should not have excessive screen reader only content
    sr_only_content = page.all('.sr-only, .screen-reader-only, [class*="visually-hidden"]')
    expect(sr_only_content.size).to be < 10 # Reasonable amount

    # Screen reader content should be meaningful
    sr_only_content.each do |element|
      expect(element.text.strip).not_to be_empty
      expect(element.text.length).to be > 2
    end
  end

  def expect_no_accessibility_anti_patterns
    # Common anti-patterns to avoid
    anti_patterns = [
      'div[onclick]', # Should use button
      'span[onclick]', # Should use button
      'img[alt*="click"]', # Alt text should describe image, not action
      '[role="button"]:not([tabindex])', # Custom buttons need tabindex
      'input[type="image"]:not([alt])' # Image inputs need alt text
    ]

    anti_patterns.each do |pattern|
      expect(page).not_to have_css(pattern),
        "Found accessibility anti-pattern: #{pattern}"
    end
  end

  # Combined accessibility audit
  def expect_full_accessibility_compliance
    expect_semantic_html
    expect_accessible_images
    expect_accessible_forms
    expect_accessible_links
    expect_accessible_buttons
    expect_sufficient_color_contrast
    expect_keyboard_navigable
    expect_proper_aria_usage
    expect_no_accessibility_anti_patterns
  end

  # Skip link functionality
  def expect_skip_links
    skip_links = page.all('a[href^="#"]').select { |link|
      link.text.downcase.include?('skip')
    }

    skip_links.each do |link|
      target_id = link[:href][1..-1] # Remove #
      expect(page).to have_css("##{target_id}")
    end
  end

  # Mobile accessibility
  def expect_mobile_accessibility
    # Touch targets should be large enough
    touch_targets = page.all('a, button, input, [role="button"]')
    touch_targets.each do |target|
      # Should have adequate size classes or styling
      classes = target[:class] || ''
      expect(classes).to match(/p-\d|py-\d|px-\d|h-\d|w-\d/) # Has sizing classes
    end
  end
end

RSpec.configure do |config|
  config.include AccessibilityHelpers, type: :view
  config.include AccessibilityHelpers, type: :system
  config.include AccessibilityHelpers, type: :feature
end
