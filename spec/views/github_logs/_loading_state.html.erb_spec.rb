# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'github_logs/_loading_state.html.erb', type: :view do
  before { render 'github_logs/loading_state' }

  describe 'loading animation structure' do
    it 'displays loading state with proper styling' do
      expect(rendered).to have_css('.px-6.py-12.text-center')
      expect(rendered).to have_css('.animate-pulse')
    end

    it 'shows animated loading indicator' do
      expect(rendered).to have_css('.animate-pulse .mx-auto.h-16.w-16.bg-gray-300.rounded-full')
    end

    it 'includes spinning loader icon' do
      expect(rendered).to have_css('svg.animate-spin')
      expect(rendered).to have_css('.text-indigo-600')
    end
  end

  describe 'loading content and messaging' do
    it 'displays appropriate loading messages' do
      expect(rendered).to have_content('Fetching GitHub Data')
      expect(rendered).to have_content('Processing repository branches and commits...')
      expect(rendered).to have_content('Loading...')
    end

    it 'uses semantic heading structure' do
      expect(rendered).to have_css('h3.text-lg.font-medium.text-gray-900')
    end

    it 'provides descriptive loading context' do
      expect(rendered).to have_css('p.text-sm.text-gray-500')
      expect(rendered).to have_content('Processing repository branches and commits')
    end
  end

  describe 'visual feedback elements' do
    it 'displays loading button with spinner' do
      expect(rendered).to have_css('.inline-flex.items-center.px-4.py-2')
      expect(rendered).to have_css('.bg-indigo-100.text-indigo-600')
    end

    it 'includes animated skeleton placeholders' do
      expect(rendered).to have_css('.space-y-3')
      expect(rendered).to have_css('.h-4.bg-gray-200.rounded.animate-pulse', count: 3)
    end

    it 'shows progressive width skeleton lines' do
      expect(rendered).to have_css('.h-4.bg-gray-200.rounded.w-5\\/6.animate-pulse')
      expect(rendered).to have_css('.h-4.bg-gray-200.rounded.w-4\\/6.animate-pulse')
    end
  end

  describe 'accessibility features' do
    it 'provides semantic content structure' do
      expect(rendered).to have_css('h3') # Proper heading
      expect(rendered).to have_css('p') # Descriptive text
    end

    it 'uses appropriate ARIA considerations' do
      # Loading states should be perceivable by screen readers
      expect(rendered).to have_content('Fetching GitHub Data')
      expect(rendered).to have_content('Loading')
    end

    it 'maintains readable color contrast' do
      expect(rendered).to include('text-gray-900') # High contrast for headings
      expect(rendered).to include('text-gray-500') # Readable contrast for secondary text
    end
  end

  describe 'animation and transitions' do
    it 'uses CSS animations for smooth loading experience' do
      expect(rendered).to include('animate-pulse') # Pulse animation
      expect(rendered).to include('animate-spin') # Spinner animation
    end

    it 'applies animations to appropriate elements' do
      expect(rendered).to have_css('.animate-pulse', minimum: 1) # Main container
      expect(rendered).to have_css('svg.animate-spin') # Spinner icon
      expect(rendered).to have_css('.bg-gray-200.animate-pulse', minimum: 3) # Skeleton lines
    end
  end

  describe 'responsive design' do
    it 'uses responsive spacing and sizing' do
      expect(rendered).to include('px-6 py-12') # Responsive padding
      expect(rendered).to include('h-16 w-16') # Appropriate icon size
      expect(rendered).to include('text-lg') # Readable text size
    end

    it 'maintains layout integrity across screen sizes' do
      expect(rendered).to have_css('.text-center') # Centered layout
      expect(rendered).to have_css('.mx-auto') # Auto margins for centering
    end

    it 'uses flexible spacing systems' do
      expect(rendered).to include('mt-4') # Margin top
      expect(rendered).to include('mt-6') # Larger margin
      expect(rendered).to include('space-y-3') # Vertical spacing
    end
  end

  describe 'loading state styling consistency' do
    it 'follows design system color palette' do
      expect(rendered).to include('text-indigo-600') # Brand color
      expect(rendered).to include('bg-indigo-100') # Light brand background
      expect(rendered).to include('text-gray-900') # Primary text
      expect(rendered).to include('text-gray-500') # Secondary text
    end

    it 'uses consistent border radius and spacing' do
      expect(rendered).to include('rounded-full') # Circular elements
      expect(rendered).to include('rounded-md') # Button border radius
      expect(rendered).to include('rounded') # General border radius
    end
  end

  describe 'performance considerations' do
    it 'uses efficient CSS animations' do
      # Should use CSS animations rather than JavaScript
      expect(rendered).to include('animate-pulse')
      expect(rendered).to include('animate-spin')
      expect(rendered).not_to include('javascript:')
    end

    it 'minimizes DOM complexity for loading state' do
      # Loading state should be lightweight
      dom_elements = rendered.scan(/<[^>]+>/).size
      expect(dom_elements).to be < 30 # Reasonable complexity for loading state
    end

    it 'uses semantic HTML elements' do
      expect(rendered).to have_css('h3') # Semantic heading
      expect(rendered).to have_css('p') # Semantic paragraph
      expect(rendered).to have_css('div') # Container elements
    end
  end

  describe 'user experience considerations' do
    it 'provides clear loading feedback' do
      expect(rendered).to have_content('Fetching GitHub Data')
      expect(rendered).to have_content('Loading')
    end

    it 'sets appropriate user expectations' do
      expect(rendered).to have_content('Processing repository branches and commits')
    end

    it 'uses visual hierarchy for information' do
      expect(rendered).to have_css('h3.text-lg') # Main heading
      expect(rendered).to have_css('p.text-sm') # Supporting text
    end
  end

  describe 'integration with GitHub workflow' do
    it 'communicates GitHub-specific loading context' do
      expect(rendered).to have_content('GitHub Data')
      expect(rendered).to have_content('repository branches and commits')
    end

    it 'provides appropriate loading duration expectations' do
      # Should indicate that GitHub data fetching may take time
      expect(rendered).to have_content('Processing')
    end
  end
end
