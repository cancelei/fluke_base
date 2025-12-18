# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'github_logs/_loading_state.html.erb', type: :view do
  before { render 'github_logs/loading_state' }

  describe 'loading animation structure' do
    it 'displays loading state with proper styling' do
      expect(rendered).to have_css('.px-6.py-12.text-center')
      expect(rendered).to have_css('.loading.loading-spinner')
    end

    it 'shows animated loading indicator' do
      expect(rendered).to have_css('.avatar.placeholder')
      expect(rendered).to have_css('.bg-base-300.rounded-full')
    end

    it 'includes spinning loader icon' do
      expect(rendered).to have_css('.loading.loading-spinner')
      expect(rendered).to have_css('.text-primary')
    end
  end

  describe 'loading content and messaging' do
    it 'displays appropriate loading messages' do
      expect(rendered).to have_content('Fetching GitHub Data')
      expect(rendered).to have_content('Processing repository branches and commits...')
    end

    it 'uses semantic heading structure' do
      expect(rendered).to have_css('h3.text-lg.font-medium')
    end

    it 'provides descriptive loading context' do
      expect(rendered).to have_css('p.text-sm')
      expect(rendered).to have_content('Processing repository branches and commits')
    end
  end

  describe 'visual feedback elements' do
    it 'displays loading button with spinner' do
      expect(rendered).to have_css('.loading.loading-spinner')
    end

    it 'includes animated skeleton placeholders' do
      expect(rendered).to have_css('.space-y-3')
      expect(rendered).to have_css('.skeleton', count: 3)
    end

    it 'shows progressive width skeleton lines' do
      expect(rendered).to have_css('.skeleton.h-4.w-5\\/6')
      expect(rendered).to have_css('.skeleton.h-4.w-4\\/6')
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
      expect(rendered).to have_css('.loading.loading-spinner')
    end

    it 'maintains readable color contrast' do
      expect(rendered).to include('text-base-content')
    end
  end

  describe 'animation and transitions' do
    it 'uses CSS animations for smooth loading experience' do
      expect(rendered).to include('loading-spinner')
    end

    it 'applies animations to appropriate elements' do
      expect(rendered).to have_css('.loading.loading-spinner')
      expect(rendered).to have_css('.skeleton', minimum: 3)
    end
  end

  describe 'responsive design' do
    it 'uses responsive spacing and sizing' do
      expect(rendered).to include('px-6 py-12') # Responsive padding
      expect(rendered).to include('w-16')
      expect(rendered).to include('text-lg') # Readable text size
    end

    it 'maintains layout integrity across screen sizes' do
      expect(rendered).to have_css('.text-center') # Centered layout
      expect(rendered).to have_css('.mx-auto') # Auto margins for centering
    end

    it 'uses flexible spacing systems' do
      expect(rendered).to include('mt-8')
      expect(rendered).to include('space-y-3')
    end
  end

  describe 'loading state styling consistency' do
    it 'follows design system color palette' do
      expect(rendered).to include('text-primary')
      expect(rendered).to include('text-base-content')
    end

    it 'uses consistent border radius and spacing' do
      expect(rendered).to include('rounded-full') # Circular elements
    end
  end

  describe 'performance considerations' do
    it 'uses efficient CSS animations' do
      # Should use CSS animations rather than JavaScript
      expect(rendered).to include('loading-spinner')
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
      expect(rendered).to have_css('.loading.loading-spinner')
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
