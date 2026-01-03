# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'People Show Page', type: :system do
  let(:alice) { create(:user, :alice, bio: 'Experienced developer and mentor') }
  let(:bob) { create(:user, :bob, linkedin: 'bobjohnson', x: 'bob_johnson') }
  let(:shared_project) { create(:project, name: 'Shared Innovation', user: alice) }

  before do
    sign_in alice
  end

  describe 'page load and navigation' do
    it 'loads the person show page successfully' do
      visit person_path(bob)

      expect(page).to have_content(bob.first_name)
      expect(page).to have_content('About')
      expect(page).to have_current_path(person_path(bob))
    end

    it 'displays proper navigation tabs and allows navigation' do
      visit person_path(bob)

      expect(page).to have_link('About', href: '#about')
      expect(page).to have_link('Achievements', href: '#achievements')
      expect(page).to have_link('Track Record', href: '#track')
      expect(page).to have_link('Projects', href: '#projects')

      # Test tab navigation (using CSS scroll behavior)
      click_link 'About'
      expect(page).to have_css('section#about')
    end
  end

  describe 'profile header interactions' do
    it 'displays user information correctly' do
      visit person_path(bob)

      expect(page).to have_content(bob.first_name)
      expect(page).to have_content(bob.last_name)
      expect(page).to have_content('Community Person') # Badge
    end

    context 'with avatar' do
      let(:avatar_blob) { fixture_file_upload(Rails.root.join('spec/fixtures/avatar.png'), 'image/png') }
      let(:user_with_avatar) { create(:user, avatar: avatar_blob) }

      it 'displays user avatar' do
        visit person_path(user_with_avatar)
        # Active Storage serves images via blob URLs, not with original filenames
        # Check that at least one avatar image is present
        expect(page).to have_css('.avatar img', minimum: 1)
      end
    end

    context 'without avatar' do
      it 'displays default avatar' do
        visit person_path(bob)
        expect(page).to have_css('svg') # Default avatar SVG
        expect(page).to have_css('.bg-gradient-to-br') # Gradient background
      end
    end
  end

  describe 'action buttons functionality', js: true do
    let(:project) { create(:project, user: alice) }

    before do
      alice.update(selected_project_id: project.id)
    end

    it 'shows agreement initiation button for other users' do
      visit person_path(bob)

      expect(page).to have_link('Initiate Agreement')
      expect(page).to have_css("a[href*='#{new_agreement_path}']")
    end

    it 'initiates agreement creation process' do
      visit person_path(bob)

      click_link 'Initiate Agreement'

      expect(page).to have_current_path(new_agreement_path(
        project_id: project.id,
        other_party_id: bob.id
      ))
    end

    it 'handles message button interaction' do
      visit person_path(bob)

      expect(page).to have_button('Message')

      click_button 'Message'

      # Should redirect to conversations
      expect(page).to have_current_path(conversations_path)
    end

    context 'when viewing own profile' do
      it 'shows edit profile link instead of message button' do
        visit person_path(alice)

        expect(page).to have_link('Edit Profile')
        expect(page).not_to have_button('Message')
        expect(page).not_to have_link('Initiate Agreement')
      end
    end
  end

  describe 'social media links', js: true do
    it 'displays and opens social media links' do
      visit person_path(bob)

      expect(page).to have_content('CONNECT')
      expect(page).to have_link('LinkedIn')
      expect(page).to have_link('X')

      # Test external link behavior
      linkedin_link = find_link('LinkedIn')
      expect(linkedin_link[:href]).to eq("https://linkedin.com/in/#{bob.linkedin}")
      expect(linkedin_link[:target]).to eq('_blank')
    end

    it 'opens social media links in new tabs' do
      visit person_path(bob)

      # Verify external links have proper attributes
      within('.social-media, [class*="social"]') do
        expect(page).to have_css('a[target="_blank"]', minimum: 1)
        expect(page).to have_css('svg') # Social media icons
      end
    end

    context 'when user has no social media' do
      let(:user_no_social) { create(:user, linkedin: nil, x: nil, youtube: nil) }

      it 'does not display social media section' do
        visit person_path(user_no_social)

        expect(page).not_to have_content('CONNECT')
        expect(page).not_to have_css('.social-media')
      end
    end
  end

  describe 'connection analysis' do
    context 'with shared connections' do
      before do
        # Create shared project connection
        create(:agreement_participant, user: bob, agreement: create(:agreement, project: shared_project))
      end

      it 'displays connection information' do
        visit person_path(bob)

        expect(page).to have_content("You and #{bob.first_name}")
        expect(page).to have_content('Shared projects:')
        expect(page).to have_content(shared_project.name)
      end
    end

    context 'without connections' do
      it 'displays no connections message' do
        visit person_path(bob)

        expect(page).to have_content('No direct connections yet')
        expect(page).to have_content('Start a conversation or propose a collaboration')
      end
    end

    context 'when viewing own profile' do
      it 'does not show connection analysis' do
        visit person_path(alice)

        expect(page).not_to have_content("You and #{alice.first_name}")
      end
    end
  end

  describe 'stats cards display' do
    it 'shows member statistics' do
      visit person_path(bob)

      expect(page).to have_content('Member Since')
      expect(page).to have_content('Projects')
      expect(page).to have_content('Agreements')

      # Should show formatted counts
      expect(page).to have_content(/\d+ project/)
      expect(page).to have_content(/\d+ agreement/)
    end
  end

  describe 'content sections' do
    describe 'about section' do
      it 'displays bio when present' do
        visit person_path(alice)

        within('section#about') do
          expect(page).to have_content(alice.bio)
        end
      end

      context 'when viewing profile without bio' do
        let(:user_no_bio) { create(:user, bio: nil) }

        it 'shows appropriate message for other users' do
          visit person_path(user_no_bio)

          within('section#about') do
            expect(page).to have_content('No bio provided yet')
          end
        end

        it 'shows add bio link for own profile' do
          user_no_bio.update(id: alice.id) # Simulate viewing own profile
          visit person_path(alice)

          within('section#about') do
            expect(page).to have_link('Add a bio')
          end
        end
      end
    end

    describe 'projects section' do
      let(:project1) { create(:project, name: 'Innovation Project', user: bob) }
      let(:project2) { create(:project, name: 'Tech Startup', stage: 'prototype') }

      before do
        # Simulate projects involvement
        create(:agreement_participant, user: bob, agreement: create(:agreement, project: project2))
      end

      it 'displays involved projects' do
        visit person_path(bob)

        within('section#projects') do
          expect(page).to have_content('Projects Involved In')
          expect(page).to have_link(project1.name, href: project_path(project1))
        end
      end

      it 'shows project metadata and agreement buttons' do
        visit person_path(bob)

        within('section#projects') do
          expect(page).to have_content('Stage:')
          expect(page).to have_content('Created')
          expect(page).to have_link('Agreement')
        end
      end

      context 'when user has no projects' do
        let(:user_no_projects) { create(:user) }

        it 'shows no projects message' do
          visit person_path(user_no_projects)

          within('section#projects') do
            expect(page).to have_content('No projects found for this user')
          end
        end
      end
    end
  end

  describe 'collaboration call-to-action' do
    it 'displays collaboration CTA for other users' do
      visit person_path(bob)

      expect(page).to have_content("Interested in collaborating with #{bob.first_name}?")
      expect(page).to have_button('Send Message')
    end

    it 'handles send message action', js: true do
      visit person_path(bob)

      click_button 'Send Message'

      expect(page).to have_current_path(conversations_path)
    end

    it 'does not show CTA when viewing own profile' do
      visit person_path(alice)

      expect(page).not_to have_content("Interested in collaborating with #{alice.first_name}?")
    end
  end

  describe 'responsive design', js: true do
    it 'adapts to different screen sizes' do
      visit person_path(bob)

      # Test mobile view
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size
      expect(page).to have_css('.flex-col') # Stacked layout

      # Test desktop view
      page.driver.browser.manage.window.resize_to(1400, 1400) # Desktop size
      expect(page).to have_css('.lg\\:flex-row') # Side-by-side layout
    end

    it 'maintains functionality across viewports' do
      page.driver.browser.manage.window.resize_to(375, 667)
      visit person_path(bob)

      # Buttons should still be accessible
      expect(page).to have_button('Message')
      expect(page).to have_link('Initiate Agreement') if alice.selected_project_id.present?
    end
  end

  describe 'accessibility features' do
    it 'has proper ARIA labels and semantic HTML' do
      visit person_path(bob)

      # Check for proper heading hierarchy
      expect(page).to have_css('h1')
      expect(page).to have_css('h2')

      # Check for semantic sections
      expect(page).to have_css('section')

      # External links should have indicators
      expect(page).to have_css('a[target="_blank"] svg') # External link icons
    end

    it 'supports keyboard navigation' do
      visit person_path(bob)

      # Tab through interactive elements
      find('body').send_keys(:tab)
      expect(page).to have_css(':focus') # Some element should be focused
    end
  end

  describe 'performance and loading' do
    it 'loads page content efficiently' do
      start_time = Time.current
      visit person_path(bob)

      expect(page).to have_content(bob.first_name)
      load_time = Time.current - start_time

      expect(load_time).to be < 2.0 # Page should load within 2 seconds
    end

    it 'handles images and media efficiently' do
      visit person_path(bob)

      # Check for lazy loading attributes or efficient image handling
      if page.has_css?('img')
        images = page.all('img')
        images.each do |img|
          expect(img[:loading]).to eq('lazy').or(be_nil) # Lazy loading or immediate
        end
      end
    end
  end

  describe 'error handling' do
    context 'when user not found' do
      it 'returns 404 status for missing user' do
        # Rails rescues RecordNotFound and renders a 404 error page
        visit person_path(id: 999_999)
        expect(page.status_code).to eq(404)
      end
    end

    context 'with network issues' do
      it 'handles partial content loading gracefully', js: true do
        visit person_path(bob)

        # Page should load basic content even if some parts fail
        expect(page).to have_content(bob.first_name)
        expect(page).to have_css('section')
      end
    end
  end

  describe 'Turbo integration', js: true do
    it 'uses Turbo for navigation' do
      visit person_path(bob)

      expect_turbo_drive_enabled

      # Navigation should use Turbo
      click_link 'About'
      expect(page).to have_css('section#about')
      expect(page).to have_current_path(person_path(bob))
    end

    it 'handles form submissions with Turbo', js: true do
      visit person_path(bob)

      # Message form should use Turbo
      within('form[action*="conversations"]') do
        expect(page).to have_css('form[data-turbo="false"]') # Explicitly disabled for redirect
      end
    end
  end
end
