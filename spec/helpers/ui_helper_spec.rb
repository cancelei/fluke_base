# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UiHelper, type: :helper do
  describe '#status_badge' do
    it 'renders badge with correct text for accepted status' do
      html = helper.status_badge('accepted')
      expect(html).to include('Accepted')
    end

    it 'renders badge for pending status' do
      html = helper.status_badge('pending')
      expect(html).to include('Pending')
    end

    it 'renders badge for rejected status' do
      html = helper.status_badge('rejected')
      expect(html).to include('Rejected')
    end

    it 'uses custom text when provided' do
      html = helper.status_badge('accepted', 'Custom Text')
      expect(html).to include('Custom Text')
    end

    it 'delegates to BadgeComponent' do
      expect(Ui::BadgeComponent).to receive(:new).with(
        hash_including(text: "Accepted", status: "accepted")
      ).and_call_original
      helper.status_badge('accepted')
    end
  end

  describe '#status_badge_class' do
    it 'returns badge class string for accepted status' do
      result = helper.status_badge_class('accepted')
      expect(result).to include('badge')
    end

    it 'returns badge class for pending status' do
      result = helper.status_badge_class('pending')
      expect(result).to include('badge')
    end

    it 'returns badge class for rejected status' do
      result = helper.status_badge_class('rejected')
      expect(result).to include('badge')
    end

    it 'handles unknown status with default variant' do
      result = helper.status_badge_class('unknown_status')
      expect(result).to include('badge')
    end

    it 'handles symbol status values' do
      result = helper.status_badge_class(:accepted)
      expect(result).to include('badge')
    end

    it 'handles uppercase status values' do
      result = helper.status_badge_class('ACCEPTED')
      expect(result).to include('badge')
    end
  end

  describe '#kpi_badge_class' do
    it 'returns badge-success for excellent status' do
      expect(helper.kpi_badge_class(:excellent)).to eq('badge-success')
    end

    it 'returns badge-info for good status' do
      expect(helper.kpi_badge_class(:good)).to eq('badge-info')
    end

    it 'returns badge-info for on_track status' do
      expect(helper.kpi_badge_class(:on_track)).to eq('badge-info')
    end

    it 'returns badge-warning for fair status' do
      expect(helper.kpi_badge_class(:fair)).to eq('badge-warning')
    end

    it 'returns badge-error for poor status' do
      expect(helper.kpi_badge_class(:poor)).to eq('badge-error')
    end

    it 'returns badge-neutral for tracking status' do
      expect(helper.kpi_badge_class(:tracking)).to eq('badge-neutral')
    end

    it 'returns badge-neutral for pending status' do
      expect(helper.kpi_badge_class(:pending)).to eq('badge-neutral')
    end

    it 'returns badge-neutral for no_data status' do
      expect(helper.kpi_badge_class(:no_data)).to eq('badge-neutral')
    end

    it 'returns badge-ghost for unknown status' do
      expect(helper.kpi_badge_class(:unknown)).to eq('badge-ghost')
    end

    it 'handles string status' do
      expect(helper.kpi_badge_class('excellent')).to eq('badge-success')
    end
  end

  describe '#render_restricted_field_message' do
    it 'renders a div container' do
      result = helper.render_restricted_field_message
      expect(result).to include('<div')
    end

    it 'includes the availability message text' do
      result = helper.render_restricted_field_message
      expect(result).to include('Available after agreement acceptance')
    end

    it 'includes flex items-center classes' do
      result = helper.render_restricted_field_message
      expect(result).to include('flex')
      expect(result).to include('items-center')
    end
  end

  describe '#collaboration_badge' do
    it 'renders badge for mentor type' do
      html = helper.collaboration_badge('mentor')
      expect(html).to include('Mentor')
    end

    it 'renders badge for co_founder type' do
      html = helper.collaboration_badge('co_founder')
      expect(html).to include('Co founder')
    end

    it 'uses custom text when provided' do
      html = helper.collaboration_badge('mentor', 'Custom Mentor')
      expect(html).to include('Custom Mentor')
    end

    it 'handles co-founder with hyphen' do
      html = helper.collaboration_badge('co-founder')
      expect(html).to include('Co-founder')
    end

    it 'uses info variant for unknown types' do
      expect(Ui::BadgeComponent).to receive(:new).with(
        hash_including(variant: :info)
      ).and_call_original
      helper.collaboration_badge('unknown')
    end
  end

  describe '#ui_button' do
    context 'with text and URL' do
      it 'renders ButtonComponent' do
        result = helper.ui_button('Click me', '/path')
        expect(result).to be_present
      end

      it 'uses primary variant by default' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(variant: :primary)
        ).and_call_original
        helper.ui_button('Click me', '/path')
      end

      it 'uses md size by default' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(size: :md)
        ).and_call_original
        helper.ui_button('Click me', '/path')
      end

      it 'renders with specified variant' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(variant: :secondary)
        ).and_call_original
        helper.ui_button('Click me', '/path', variant: :secondary)
      end

      it 'renders with specified size' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(size: :lg)
        ).and_call_original
        helper.ui_button('Click me', '/path', size: :lg)
      end

      it 'passes icon option to component' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(icon: :plus)
        ).and_call_original
        helper.ui_button('Add', '/path', icon: :plus)
      end

      it 'passes method option for non-GET requests' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(method: :delete)
        ).and_call_original
        helper.ui_button('Delete', '/path', method: :delete)
      end

      it 'passes data attributes to component' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(data: { confirm: 'Sure?' })
        ).and_call_original
        helper.ui_button('Delete', '/path', data: { confirm: 'Sure?' })
      end

      it 'passes custom CSS class' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(css_class: 'my-class')
        ).and_call_original
        helper.ui_button('Click', '/path', class: 'my-class')
      end
    end

    context 'with options hash only (no URL)' do
      it 'renders button without URL' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(url: nil)
        ).and_call_original
        helper.ui_button('Click', variant: :primary)
      end
    end

    context 'size normalization' do
      it 'converts :default size to :md' do
        expect(Ui::ButtonComponent).to receive(:new).with(
          hash_including(size: :md)
        ).and_call_original
        helper.ui_button('Click', '/path', size: :default)
      end
    end

    context 'with block content' do
      it 'yields block to component' do
        result = helper.ui_button('Click', '/path') { 'Block content' }
        expect(result).to be_present
      end
    end

    it 'passes empty data hash by default' do
      expect(Ui::ButtonComponent).to receive(:new).with(
        hash_including(data: {})
      ).and_call_original
      helper.ui_button('Click', '/path')
    end
  end

  describe '#ui_icon' do
    it 'renders IconComponent with icon name' do
      expect(Ui::IconComponent).to receive(:new).with(
        hash_including(name: :check)
      ).and_call_original
      helper.ui_icon(:check)
    end

    it 'returns empty string for nil icon name' do
      expect(helper.ui_icon(nil)).to eq('')
    end

    it 'returns empty string for blank icon name' do
      expect(helper.ui_icon('')).to eq('')
    end

    it 'passes class option as css_class' do
      expect(Ui::IconComponent).to receive(:new).with(
        hash_including(css_class: 'my-icon')
      ).and_call_original
      helper.ui_icon(:check, class: 'my-icon')
    end

    it 'uses medium size by default' do
      expect(Ui::IconComponent).to receive(:new).with(
        hash_including(size: :md)
      ).and_call_original
      helper.ui_icon(:check)
    end
  end

  describe '#ui_badge' do
    it 'renders BadgeComponent with text' do
      expect(Ui::BadgeComponent).to receive(:new).with(
        hash_including(text: 'Active')
      ).and_call_original
      helper.ui_badge('Active')
    end

    it 'uses primary variant by default' do
      expect(Ui::BadgeComponent).to receive(:new).with(
        hash_including(variant: :primary)
      ).and_call_original
      helper.ui_badge('Test')
    end

    it 'passes custom variant' do
      expect(Ui::BadgeComponent).to receive(:new).with(
        hash_including(variant: :success)
      ).and_call_original
      helper.ui_badge('Test', :success)
    end

    it 'passes custom css_class' do
      expect(Ui::BadgeComponent).to receive(:new).with(
        hash_including(css_class: 'my-badge')
      ).and_call_original
      helper.ui_badge('Test', :primary, class: 'my-badge')
    end
  end

  describe '#ui_card' do
    it 'renders CardComponent' do
      result = helper.ui_card { 'Content' }
      expect(result).to be_present
    end

    it 'uses default variant by default' do
      expect(Ui::CardComponent).to receive(:new).with(
        hash_including(variant: :default)
      ).and_call_original
      helper.ui_card { 'Content' }
    end

    it 'passes custom variant' do
      expect(Ui::CardComponent).to receive(:new).with(
        hash_including(variant: :bordered)
      ).and_call_original
      helper.ui_card(variant: :bordered) { 'Content' }
    end

    it 'passes custom css_class' do
      expect(Ui::CardComponent).to receive(:new).with(
        hash_including(css_class: 'my-card')
      ).and_call_original
      helper.ui_card(class: 'my-card') { 'Content' }
    end

    it 'yields block content' do
      result = helper.ui_card { 'Card content' }
      expect(result).to be_present
    end
  end

  describe '#ui_card_header' do
    it 'renders div with border-b class' do
      result = helper.ui_card_header('Title')
      expect(result).to include('border-b')
    end

    it 'includes title in h3 element' do
      result = helper.ui_card_header('My Title')
      expect(result).to include('<h3')
      expect(result).to include('My Title')
    end

    it 'includes card-title class on h3' do
      result = helper.ui_card_header('Title')
      expect(result).to include('card-title')
    end

    it 'includes subtitle when provided' do
      result = helper.ui_card_header('Title', 'Subtitle')
      expect(result).to include('<p')
      expect(result).to include('Subtitle')
    end

    it 'omits subtitle p when not provided' do
      result = helper.ui_card_header('Title')
      expect(result).not_to include('<p')
    end

    it 'omits subtitle p when nil' do
      result = helper.ui_card_header('Title', nil)
      expect(result).not_to include('<p')
    end

    it 'applies custom class' do
      result = helper.ui_card_header('Title', nil, class: 'custom-header')
      expect(result).to include('custom-header')
    end

    it 'includes padding classes' do
      result = helper.ui_card_header('Title')
      expect(result).to include('px-6')
      expect(result).to include('py-4')
    end
  end

  describe '#ui_empty_state' do
    it 'renders EmptyStateComponent' do
      result = helper.ui_empty_state('No items', 'Add some')
      expect(result).to be_present
    end

    it 'passes title to component' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(title: 'No items')
      ).and_call_original
      helper.ui_empty_state('No items', 'Add some')
    end

    it 'passes description to component' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(description: 'Add some')
      ).and_call_original
      helper.ui_empty_state('No items', 'Add some')
    end

    it 'uses folder icon by default' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(icon: :folder)
      ).and_call_original
      helper.ui_empty_state('Title', 'Description')
    end

    it 'passes custom icon' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(icon: :users)
      ).and_call_original
      helper.ui_empty_state('Title', 'Description', nil, nil, icon: :users)
    end

    it 'passes action_text' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(action_text: 'Add Item')
      ).and_call_original
      helper.ui_empty_state('Title', 'Description', 'Add Item', '/items/new')
    end

    it 'passes action_url' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(action_url: '/items/new')
      ).and_call_original
      helper.ui_empty_state('Title', 'Description', 'Add Item', '/items/new')
    end

    it 'passes css_class option' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(css_class: 'my-empty')
      ).and_call_original
      helper.ui_empty_state('Title', 'Description', nil, nil, class: 'my-empty')
    end

    it 'passes nil action_text and action_url' do
      expect(Ui::EmptyStateComponent).to receive(:new).with(
        hash_including(action_text: nil, action_url: nil)
      ).and_call_original
      helper.ui_empty_state('Title', 'Description')
    end
  end

  describe '#ui_search_form' do
    it 'renders a form element' do
      result = helper.ui_search_form('/search')
      expect(result).to include('<form')
    end

    it 'includes search input' do
      result = helper.ui_search_form('/search')
      expect(result).to include('type="text"')
      expect(result).to include('name="search"')
    end

    it 'includes submit button' do
      result = helper.ui_search_form('/search')
      expect(result).to include('type="submit"')
    end

    it 'uses default placeholder when not specified' do
      result = helper.ui_search_form('/search')
      expect(result).to include('placeholder="Search..."')
    end

    it 'uses custom placeholder when specified' do
      result = helper.ui_search_form('/search', placeholder: 'Find users...')
      expect(result).to include('placeholder="Find users..."')
    end

    it 'uses default submit text' do
      result = helper.ui_search_form('/search')
      expect(result).to include('value="Search"')
    end

    it 'uses custom submit text' do
      result = helper.ui_search_form('/search', submit_text: 'Find')
      expect(result).to include('value="Find"')
    end

    it 'uses GET method by default' do
      result = helper.ui_search_form('/search')
      # Forms with GET don't have method="get" explicitly, but action should be present
      expect(result).to include('action="/search"')
    end

    it 'uses custom method when specified' do
      result = helper.ui_search_form('/search', method: :post)
      expect(result).to include('method="post"')
    end

    it 'populates search value from params' do
      allow(helper).to receive(:params).and_return({ search: 'test query' })
      result = helper.ui_search_form('/search')
      expect(result).to include('value="test query"')
    end

    it 'uses custom search_value when provided' do
      result = helper.ui_search_form('/search', search_value: 'custom value')
      expect(result).to include('value="custom value"')
    end
  end

  describe '#stage_badge' do
    it 'renders badge with capitalized text' do
      html = helper.stage_badge('idea')
      expect(html).to include('Idea')
    end

    it 'renders badge for different stages' do
      html = helper.stage_badge('development')
      expect(html).to include('Development')
    end

    it 'returns empty string for nil stage' do
      expect(helper.stage_badge(nil)).to eq('')
    end

    it 'returns empty string for blank stage' do
      expect(helper.stage_badge('')).to eq('')
    end

    it 'delegates to BadgeComponent with info variant' do
      expect(Ui::BadgeComponent).to receive(:new).with(
        hash_including(variant: :info)
      ).and_call_original
      helper.stage_badge('idea')
    end
  end
end
