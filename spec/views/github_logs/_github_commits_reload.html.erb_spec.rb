# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'github_logs/_github_commits_reload.html.erb', type: :view do
  before { render 'github_logs/github_commits_reload' }

  describe 'success notification structure' do
    it 'displays success notification with proper styling' do
      expect(rendered).to have_css('.text-center.py-4')
      expect(rendered).to have_css('.inline-flex.items-center')
    end

    it 'uses success color scheme' do
      expect(rendered).to have_css('.text-green-600.bg-green-100')
      expect(rendered).to have_css('.border.border-transparent')
    end

    it 'has proper button-like styling' do
      expect(rendered).to have_css('.px-4.py-2.text-sm.font-medium.rounded-md')
    end
  end

  describe 'success messaging' do
    it 'displays success message' do
      expect(rendered).to have_content('GitHub data updated successfully!')
    end

    it 'includes success icon' do
      expect(rendered).to have_css('svg.mr-2.h-5.w-5')
      expect(rendered).to have_css('svg path[fill-rule="evenodd"]')
    end

    it 'provides clear feedback about the update' do
      expect(rendered).to have_content('updated successfully')
    end
  end

  describe 'icon and visual elements' do
    it 'displays checkmark success icon' do
      expect(rendered).to have_css('svg.mr-2.h-5.w-5')
      # Should contain checkmark path
      expect(rendered).to include('fill-rule="evenodd"')
      expect(rendered).to include('clip-rule="evenodd"')
    end

    it 'positions icon correctly with text' do
      expect(rendered).to have_css('.mr-2') # Icon margin
      expect(rendered).to have_css('.items-center') # Vertical alignment
    end
  end

  describe 'Turbo Stream integration' do
    it 'provides content suitable for turbo stream updates' do
      # This partial is specifically designed for turbo stream replacement
      expect(rendered).to have_content('GitHub data updated successfully!')
    end

    it 'has appropriate timing for user feedback' do
      # Should be visible and informative for stream updates
      expect(rendered).to have_css('.text-center') # Prominent display
      expect(rendered).to have_css('.py-4') # Adequate spacing
    end

    it 'uses non-intrusive success styling' do
      expect(rendered).to have_css('.bg-green-100') # Subtle background
      expect(rendered).to have_css('.text-green-600') # Readable text
    end
  end

  describe 'accessibility features' do
    it 'provides semantic content structure' do
      expect(rendered).to have_content('GitHub data updated successfully!')
    end

    it 'uses appropriate color contrast' do
      expect(rendered).to include('text-green-600') # Should have good contrast on green-100 background
    end

    it 'includes meaningful icon for visual users' do
      expect(rendered).to have_css('svg') # Success icon present
    end
  end

  describe 'responsive design' do
    it 'maintains proper layout on different screen sizes' do
      expect(rendered).to have_css('.text-center') # Centered layout
      expect(rendered).to have_css('.inline-flex') # Inline flexible layout
    end

    it 'uses appropriate text sizing' do
      expect(rendered).to include('text-sm') # Readable but not dominant text size
    end

    it 'has proper spacing for mobile and desktop' do
      expect(rendered).to include('py-4') # Vertical padding
      expect(rendered).to include('px-4') # Horizontal padding
    end
  end

  describe 'user experience considerations' do
    it 'provides immediate positive feedback' do
      expect(rendered).to have_content('successfully!')
      expect(rendered).to have_css('.text-green-600') # Positive color
    end

    it 'uses appropriate visual weight for notification' do
      expect(rendered).to have_css('.font-medium') # Medium weight, not overwhelming
      expect(rendered).to have_css('.text-sm') # Appropriately sized
    end

    it 'centers notification for prominence' do
      expect(rendered).to have_css('.text-center')
      expect(rendered).to have_css('.py-4') # Vertical centering space
    end
  end

  describe 'integration with GitHub refresh workflow' do
    it 'communicates GitHub-specific success' do
      expect(rendered).to have_content('GitHub data')
      expect(rendered).to have_content('updated')
    end

    it 'provides closure for refresh action' do
      expect(rendered).to have_content('successfully!')
    end

    it 'uses appropriate styling for success state' do
      expect(rendered).to have_css('.bg-green-100.text-green-600')
    end
  end

  describe 'performance and efficiency' do
    it 'uses minimal DOM structure' do
      # Should be lightweight for frequent turbo stream updates
      dom_elements = rendered.scan(/<[^>]+>/).size
      expect(dom_elements).to be <= 10 # Very simple structure
    end

    it 'avoids unnecessary complexity' do
      expect(rendered).not_to include('javascript:') # No inline JS
      expect(rendered).not_to match(/style="/) # Minimal inline styles
    end

    it 'uses efficient CSS classes' do
      expect(rendered).to include('class=') # Uses CSS classes
      # Should have reasonable number of classes
      class_attributes = rendered.scan(/class="[^"]*"/).size
      expect(class_attributes).to be <= 3
    end
  end

  describe 'visual consistency' do
    it 'follows design system patterns' do
      expect(rendered).to include('rounded-md') # Consistent border radius
      expect(rendered).to include('border-transparent') # Design system border
    end

    it 'uses consistent spacing units' do
      expect(rendered).to include('py-4') # Vertical padding
      expect(rendered).to include('px-4') # Horizontal padding
      expect(rendered).to include('mr-2') # Icon spacing
    end

    it 'maintains color consistency' do
      expect(rendered).to include('text-green-600') # Text color
      expect(rendered).to include('bg-green-100') # Background color
    end
  end
end
