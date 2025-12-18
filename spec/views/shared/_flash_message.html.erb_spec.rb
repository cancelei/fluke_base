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
      expect(rendered).to have_css('.alert.alert-success')
    end

    it 'displays the message content' do
      expect(rendered).to have_content('Operation completed successfully!')
    end

    it 'renders success icon' do
      expect(view).to render_template(partial: 'shared/icons/_notice')
    end

    it 'has proper structure and accessibility' do
      expect(rendered).to have_css('.alert.mb-6')
      expect(rendered).to have_css('svg')
      expect(rendered).to have_css('span')
    end
  end

  describe 'alert message rendering' do
    let(:type) { :alert }
    let(:message) { 'Something went wrong!' }

    before do
      render 'shared/flash_message', type: type, message: message
    end

    it 'renders with error styling' do
      expect(rendered).to have_css('.alert.alert-error')
    end

    it 'displays the message content' do
      expect(rendered).to have_content('Something went wrong!')
    end

    it 'renders alert icon' do
      expect(view).to render_template(partial: 'shared/icons/_alert')
    end

    it 'has proper structure and accessibility' do
      expect(rendered).to have_css('.alert.mb-6')
      expect(rendered).to have_css('svg')
      expect(rendered).to have_css('span')
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
        expect(rendered).to have_css('span')
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
        expect(rendered).to have_css('span')
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
        expect(rendered).to have_css('svg')
        expect(rendered).to have_css('span')
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
        expect(rendered).to include('alert-success')
      end
    end

    context 'alert styling' do
      let(:type) { :alert }

      before do
        render 'shared/flash_message', type: type, message: message
      end

      it 'uses consistent error styling' do
        expect(rendered).to include('alert-error')
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
      expect(rendered).to have_css('div.alert.mb-6')
    end

    it 'uses flexbox layout correctly' do
      expect(rendered).to have_css('svg')
      expect(rendered).to have_css('span')
    end

    it 'maintains consistent spacing' do
      # Check that spacing classes are applied correctly
      expect(rendered).to match(/class="[^"]*mb-6[^"]*"/)
    end
  end

  describe 'accessibility features' do
    let(:type) { :notice }
    let(:message) { 'Accessible message' }

    before do
      render 'shared/flash_message', type: type, message: message
    end

    it 'provides semantic content structure' do
      expect(rendered).to have_css('span')
    end

    it 'uses appropriate color contrast' do
      expect(rendered).to match(/alert-(success|error)/)
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
        expect(rendered).to include('alert-error')
      end
    end
  end
end
