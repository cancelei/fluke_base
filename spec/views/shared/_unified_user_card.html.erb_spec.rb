# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_unified_user_card.html.erb', type: :view do
  let(:current_user) { create(:user, :alice) }
  let(:user) { create(:user, :bob, bio: 'Experienced developer and mentor') }
  let(:project) { create(:project, user: user) }

  before do
    allow(view).to receive(:current_user).and_return(current_user)
    allow(user).to receive(:projects).and_return([ project ])
    allow(user).to receive(:all_agreements).and_return(double('agreements', where: double('accepted_agreements', count: 2)))
    # Include route helpers for view tests
    view.extend ActionView::Helpers::UrlHelper
    view.extend Rails.application.routes.url_helpers
  end

  describe 'basic card structure' do
    before { render 'shared/unified_user_card', user: user }

    it 'renders main card as a proper link with styling' do
      expect(rendered).to have_css("a[href='#{person_path(user)}']")
      expect(rendered).to have_css('.block.bg-white\\/80.backdrop-blur-sm.border.border-white\\/30.rounded-2xl.shadow-lg.cursor-pointer.group.relative')
    end

    it 'includes proper Rails link navigation' do
      expect(rendered).to have_link(href: person_path(user))
      expect(rendered).to have_css('a[data-turbo-frame="_top"]')
    end

    it 'has hover effects and transitions' do
      expect(rendered).to include('hover:shadow-xl')
      expect(rendered).to include('hover:-translate-y-1')
      expect(rendered).to include('transition-all duration-300')
    end
  end

  describe 'avatar section' do
    context 'with attached avatar' do
      before do
        user.avatar.attach(io: StringIO.new('image-bytes'), filename: 'avatar.jpg', content_type: 'image/jpeg')
        render 'shared/unified_user_card', user: user
      end

      it 'displays user avatar image' do
        expect(rendered).to have_css('img.h-full.w-full.object-cover')
      end

      it 'includes gradient overlay on avatar' do
        expect(rendered).to have_css('.absolute.inset-0.bg-gradient-to-t.from-black\\/10.to-transparent')
      end
    end

    context 'without attached avatar' do
      before do
        allow(user).to receive(:avatar).and_return(double('avatar', attached?: false))
        render 'shared/unified_user_card', user: user
      end

      it 'displays default avatar SVG' do
        expect(rendered).to have_css('svg.h-16.w-16.text-indigo-300')
      end

      it 'uses gradient background for default avatar' do
        expect(rendered).to have_css('.bg-gradient-to-br.from-indigo-100.to-purple-100')
      end
    end

    context 'with custom avatar height option' do
      before do
        render 'shared/unified_user_card', user: user, options: { avatar_height: 'h-32' }
      end

      it 'uses custom avatar height' do
        expect(rendered).to have_css('.h-32')
        expect(rendered).not_to have_css('.h-40') # Default height
      end
    end
  end

  describe 'user information display' do
    before { render 'shared/unified_user_card', user: user }

    it 'displays user full name' do
      expect(rendered).to have_content(user.full_name)
      expect(rendered).to have_css('h3.text-lg.font-bold.text-gray-900.truncate')
    end

    it 'displays community badge' do
      expect(rendered).to have_content('Community Person')
      expect(rendered).to have_css('.bg-gradient-to-r.from-indigo-100.to-purple-100.text-indigo-700')
    end

    it 'displays user bio' do
      expect(rendered).to have_content(user.bio)
      expect(rendered).to have_css('.text-sm.text-gray-600.line-clamp-2')
    end

    context 'when user has no bio' do
      let(:user) { create(:user, :bob, bio: nil) }

      before { render 'shared/unified_user_card', user: user }

      it 'displays default bio text' do
        expect(rendered).to have_content('Passionate member of the FlukeBase community')
      end
    end
  end

  describe 'skills section' do
    context 'when user has skills' do
      let(:user) { create(:user, :bob, skills: [ 'Ruby', 'Rails', 'JavaScript', 'Python', 'React' ]) }

      before do
        allow(user).to receive(:skills).and_return([ 'Ruby', 'Rails', 'JavaScript', 'Python', 'React' ])
        render 'shared/unified_user_card', user: user
      end

      it 'displays first 3 skills' do
        expect(rendered).to have_content('Ruby')
        expect(rendered).to have_content('Rails')
        expect(rendered).to have_content('JavaScript')
      end

      it 'shows additional skills count' do
        expect(rendered).to have_content('+2 more')
      end

      it 'styles skills with proper badges' do
        expect(rendered).to have_css('.bg-indigo-50.text-indigo-700.border.border-indigo-100')
      end
    end

    context 'when user has 3 or fewer skills' do
      let(:user) { create(:user, :bob, skills: [ 'Ruby', 'Rails' ]) }

      before do
        allow(user).to receive(:skills).and_return([ 'Ruby', 'Rails' ])
        render 'shared/unified_user_card', user: user
      end

      it 'displays all skills without more indicator' do
        expect(rendered).to have_content('Ruby')
        expect(rendered).to have_content('Rails')
        expect(rendered).not_to have_content('more')
      end
    end

    context 'when user has no skills' do
      before do
        allow(user).to receive(:skills).and_return(nil)
        render 'shared/unified_user_card', user: user
      end

      it 'does not display skills section' do
        expect(rendered).not_to have_css('.bg-indigo-50')
      end
    end
  end

  describe 'stats section' do
    before { render 'shared/unified_user_card', user: user }

    it 'displays projects count with icon' do
      expect(rendered).to have_content('1 project')
      expect(rendered).to have_css('svg.h-4.w-4.mr-1.text-indigo-400')
    end

    it 'displays collaborations count with icon' do
      expect(rendered).to have_content('2 collaborations')
      expect(rendered).to have_css('svg.h-4.w-4.mr-1.text-purple-400')
    end

    it 'uses proper text styling for stats' do
      expect(rendered).to have_css('.text-xs.text-gray-500')
    end
  end

  describe 'message button functionality' do
    context 'when viewing other user card' do
      before { render 'shared/unified_user_card', user: user }

      it 'displays connect button' do
        expect(rendered).to have_button('Connect')
        expect(rendered).to have_css('.cta-btn')
      end

      it 'creates conversation form' do
        expect(rendered).to have_css("form[action*='#{conversations_path}']")
        expect(rendered).to have_css("input[name='recipient_id'][value='#{user.id}']", visible: false)
      end

      it 'uses proper button styling' do
        expect(rendered).to have_css('.bg-gradient-to-r.from-indigo-600.to-purple-600')
        expect(rendered).to have_css('.hover\\:from-indigo-700.hover\\:to-purple-700')
      end
    end

    context 'when viewing own user card' do
      let(:user) { current_user }

      before { render 'shared/unified_user_card', user: user }

      it 'does not display connect button' do
        expect(rendered).not_to have_button('Connect')
      end
    end

    context 'with show_message_button option disabled' do
      before do
        render 'shared/unified_user_card', user: user, options: { show_message_button: false }
      end

      it 'does not display connect button' do
        expect(rendered).not_to have_button('Connect')
      end
    end
  end

  describe 'custom content options' do
    let(:custom_content) { '<div class="custom-content">Custom Content</div>'.html_safe }
    let(:custom_stats) { 'Custom stats information' }

    before do
      render 'shared/unified_user_card',
        user: user,
        options: {
          custom_content: custom_content,
          custom_stats: custom_stats
        }
    end

    it 'renders custom content' do
      expect(rendered).to have_css('.custom-content')
      expect(rendered).to have_content('Custom Content')
    end

    it 'renders custom stats' do
      expect(rendered).to have_content('Custom stats information')
      expect(rendered).to have_css('.text-xs.text-gray-600')
    end
  end

  describe 'footer section' do
    before { render 'shared/unified_user_card', user: user }

    it 'displays view profile link' do
      expect(rendered).to have_content('View Profile')
      expect(rendered).to have_css('.text-indigo-600.transition.group-hover\\:text-indigo-800')
    end

    it 'has proper footer styling' do
      expect(rendered).to have_css('.border-t.border-gray-100\\/50')
      expect(rendered).to have_css('.bg-gradient-to-r.from-white\\/50.to-gray-50\\/50')
      expect(rendered).to have_css('.rounded-b-2xl')
    end

    it 'creates flexible footer layout' do
      expect(rendered).to have_css('.flex.items-center.justify-between')
    end
  end

  describe 'accessibility features' do
    before { render 'shared/unified_user_card', user: user }

    it 'provides semantic content structure' do
      expect(rendered).to have_css('h3') # User name as heading
      expect(rendered).to have_css('p') # Bio in paragraph
    end

    it 'includes proper ARIA considerations' do
      # Interactive card should be accessible
      expect(rendered).to have_css("a[href='#{person_path(user)}']") # Navigation target
      expect(rendered).to have_css('.cursor-pointer') # Visual indication of interactivity
    end

    it 'uses accessible color combinations' do
      expect(rendered).to include('text-gray-900') # High contrast for names
      expect(rendered).to include('text-gray-600') # Readable contrast for secondary text
    end

    it 'provides focus management' do
      expect(rendered).to have_css('.focus\\:outline-none') # Focus styles for buttons
      expect(rendered).to have_css('.focus\\:ring-2') # Focus rings for accessibility
    end
  end

  describe 'responsive design' do
    before do
      allow(user).to receive(:skills).and_return([ 'Ruby' ])
      render 'shared/unified_user_card', user: user
    end

    it 'uses responsive layout patterns' do
      expect(rendered).to include('rounded-2xl') # Consistent border radius
      expect(rendered).to include('p-5') # Responsive padding
    end

    it 'handles text overflow properly' do
      expect(rendered).to have_css('.truncate') # Name truncation
      expect(rendered).to have_css('.line-clamp-2') # Bio line clamping
    end

    it 'uses flexible layout systems' do
      expect(rendered).to have_css('.flex') # Flexible layouts
      expect(rendered).to have_css('.flex-wrap') # Wrapping for skills
    end
  end

  describe 'interaction handling' do
    before { render 'shared/unified_user_card', user: user }

    it 'prevents button clicks from triggering card navigation' do
      expect(rendered).to include("event.stopPropagation(); event.preventDefault(); this.form.submit();")
    end

    it 'handles card click navigation with proper Rails link' do
      expect(rendered).to have_link(href: person_path(user))
      expect(rendered).to have_css('a[data-turbo-frame="_top"]')
    end

    it 'provides proper z-index for interactive elements' do
      expect(rendered).to include('relative z-10') # Button z-index
    end
  end

  describe 'performance optimizations' do
    before { render 'shared/unified_user_card', user: user }

    it 'uses efficient CSS classes' do
      expect(rendered).to include('backdrop-blur-sm') # Efficient backdrop effects
      expect(rendered).to include('transition-all duration-300') # Smooth transitions
    end

    it 'minimizes DOM complexity' do
      # Card should be efficient while feature-rich
      dom_elements = rendered.scan(/<[^>]+>/).size
      expect(dom_elements).to be < 50 # Reasonable DOM complexity
    end

    it 'uses semantic HTML elements' do
      expect(rendered).to have_css('h3') # Semantic heading
      expect(rendered).to have_css('p') # Semantic paragraph
      expect(rendered).to have_css('span') # Semantic inline elements
    end
  end

  describe 'error handling' do
    context 'when user associations fail' do
      before do
        allow(user).to receive(:projects).and_raise(ActiveRecord::RecordNotFound)
      end

      it 'handles missing associations gracefully' do
        expect { render 'shared/unified_user_card', user: user }.to raise_error(ActionView::Template::Error)
      end
    end

    context 'with invalid options' do
      before do
        render 'shared/unified_user_card', user: user, options: { invalid_option: 'test' }
      end

      it 'ignores invalid options gracefully' do
        expect(rendered).to have_content(user.full_name)
      end
    end

    context 'when user has missing data' do
      let(:incomplete_user) { build(:user, first_name: '', last_name: '', bio: nil) }

      before { render 'shared/unified_user_card', user: incomplete_user }

      it 'handles incomplete user data gracefully' do
        expect(rendered).to have_content('Community Person')
        expect(rendered).to have_content('Passionate member of the FlukeBase community')
      end
    end
  end
end
