# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_flash_message.html.erb', type: :view do
  describe 'notice message rendering' do
    let(:type) { :notice }
    let(:message) { 'Operation completed successfully!' }

    before do
      render 'shared/flash_message', type: type, message: message
    end

    it 'renders with success styling' do
      expect(rendered).to have_css('.bg-green-50') # Success background
      expect(rendered).to have_css('.text-green-800') # Success text color
    end

    it 'displays the message content' do
      expect(rendered).to have_content('Operation completed successfully!')
    end

    it 'renders success icon' do
      expect(view).to render_template(partial: 'shared/icons/_notice')
    end

    it 'has proper structure and accessibility' do
      expect(rendered).to have_css('.rounded-md') # Proper styling
      expect(rendered).to have_css('.p-4') # Adequate padding
      expect(rendered).to have_css('.mb-6') # Proper spacing
      expect(rendered).to have_css('.flex') # Flexible layout
    end
  end

  describe 'alert message rendering' do
    let(:type) { :alert }
    let(:message) { 'Something went wrong!' }

    before do
      render 'shared/flash_message', type: type, message: message
    end

    it 'renders with error styling' do
      expect(rendered).to have_css('.bg-red-50') # Error background
      expect(rendered).to have_css('.text-red-800') # Error text color
    end

    it 'displays the message content' do
      expect(rendered).to have_content('Something went wrong!')
    end

    it 'renders alert icon' do
      expect(view).to render_template(partial: 'shared/icons/_alert')
    end

    it 'has proper structure and accessibility' do
      expect(rendered).to have_css('.rounded-md')
      expect(rendered).to have_css('.p-4')
      expect(rendered).to have_css('.mb-6')
      expect(rendered).to have_css('.flex')
    end
  end

  describe 'message content handling' do
    let(:type) { :notice }

    context 'with plain text message' do
      let(:message) { 'Simple success message' }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'renders plain text safely' do
        expect(rendered).to have_content('Simple success message')
        expect(rendered).to have_css('p.text-sm.font-medium')
      end
    end

    context 'with HTML content in message' do
      let(:message) { 'Success! <a href="/dashboard">Go to dashboard</a>' }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'renders HTML content safely' do
        expect(rendered).to have_content('Success!')
        expect(rendered).to have_link('Go to dashboard', href: '/dashboard')
      end
    end

    context 'with very long message' do
      let(:message) { 'This is a very long message that should wrap properly and not break the layout even on smaller screens or narrow containers' }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'handles long messages gracefully' do
        expect(rendered).to have_content('This is a very long message')
        expect(rendered).to have_css('p') # Should be wrapped in paragraph
        # Should not have fixed width that breaks responsive design
        expect(rendered).not_to match(/style=".*width:\s*\d+px.*"/)
      end
    end

    context 'with special characters' do
      let(:message) { 'Message with "quotes" & ampersands < > symbols' }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'safely escapes special characters' do
        expect(rendered).to include('&quot;quotes&quot;') # Quotes escaped
        expect(rendered).to include('&amp;') # Ampersand escaped
        expect(rendered).to include('&lt;') # Less than escaped
        expect(rendered).to include('&gt;') # Greater than escaped
      end
    end
  end

  describe 'icon integration' do
    let(:message) { 'Test message' }

    context 'with notice type' do
      let(:type) { :notice }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'renders notice icon partial' do
        expect(view).to render_template(partial: 'shared/icons/_notice')
      end

      it 'positions icon correctly' do
        expect(rendered).to have_css('.flex-shrink-0') # Icon container
        expect(rendered).to have_css('.ml-3') # Text positioned correctly
      end
    end

    context 'with alert type' do
      let(:type) { :alert }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'renders alert icon partial' do
        expect(view).to render_template(partial: 'shared/icons/_alert')
      end
    end
  end

  describe 'styling consistency' do
    let(:message) { 'Test message' }

    context 'notice styling' do
      let(:type) { :notice }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'uses consistent success styling' do
        expect(rendered).to include('bg-green-50') # Background
        expect(rendered).to include('text-green-800') # Text color
        expect(rendered).to include('text-sm font-medium') # Typography
      end
    end

    context 'alert styling' do
      let(:type) { :alert }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'uses consistent error styling' do
        expect(rendered).to include('bg-red-50') # Background
        expect(rendered).to include('text-red-800') # Text color
        expect(rendered).to include('text-sm font-medium') # Typography
      end
    end
  end

  describe 'layout and spacing' do
    let(:type) { :notice }
    let(:message) { 'Test message' }

    before do
      render 'shared/flash_message', type: type, message: message
    end

    it 'has proper container structure' do
      expect(rendered).to have_css('div.rounded-md') # Main container
      expect(rendered).to have_css('.p-4') # Inner padding
      expect(rendered).to have_css('.mb-6') # Bottom margin
    end

    it 'uses flexbox layout correctly' do
      expect(rendered).to have_css('.flex') # Main flex container
      expect(rendered).to have_css('.flex-shrink-0') # Icon container
      expect(rendered).to have_css('.ml-3') # Text container margin
    end

    it 'maintains consistent spacing' do
      # Check that spacing classes are applied correctly
      expect(rendered).to match(/class="[^"]*p-4[^"]*"/) # Padding
      expect(rendered).to match(/class="[^"]*mb-6[^"]*"/) # Margin bottom
      expect(rendered).to match(/class="[^"]*ml-3[^"]*"/) # Text margin left
    end
  end

  describe 'accessibility features' do
    let(:type) { :notice }
    let(:message) { 'Accessible message' }

    before do
      render 'shared/flash_message', type: type, message: message
    end

    it 'provides semantic content structure' do
      expect(rendered).to have_css('p') # Message in paragraph tag
      expect(rendered).to have_css('.font-medium') # Proper text weight for readability
    end

    it 'uses appropriate color contrast' do
      # Green-800 on green-50 and red-800 on red-50 should have good contrast
      expect(rendered).to match(/text-(green|red)-800/)
      expect(rendered).to match(/bg-(green|red)-50/)
    end

    it 'supports screen reader navigation' do
      # Message should be readable by screen readers
      expect(rendered).to have_content('Accessible message')
      # Should not have presentation-only elements that confuse screen readers
      expect(rendered).not_to have_css('[role="presentation"]')
    end
  end

  describe 'error handling' do
    context 'with nil message' do
      let(:type) { :notice }
      let(:message) { nil }

      it 'handles nil message gracefully' do
        expect { render 'shared/flash_message', type: type, message: message }.not_to raise_error
      end
    end

    context 'with unknown type' do
      let(:type) { :unknown }
      let(:message) { 'Test message' }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'defaults to alert styling for unknown types' do
        expect(rendered).to include('bg-red-50') # Should default to alert styling
        expect(rendered).to include('text-red-800')
      end
    end
  end
end
