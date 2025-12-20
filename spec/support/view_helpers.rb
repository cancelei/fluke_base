# frozen_string_literal: true

# View testing helpers for Rails 8.0.2
# Provides utilities for comprehensive view component testing
module ViewHelpers
  # Presenter testing helpers
  def stub_presenter_method(presenter_class, method_name, return_value)
    allow_any_instance_of(presenter_class).to receive(method_name).and_return(return_value)
  end

  def expect_presenter_call(presenter_class, method_name)
    expect_any_instance_of(presenter_class).to receive(method_name)
  end

  # Social media link testing
  def expect_social_media_links(user, platforms = %w[linkedin x youtube facebook tiktok])
    platforms.each do |platform|
      next unless user.public_send(platform).present?

      case platform
      when 'linkedin'
        expect(rendered).to have_link('LinkedIn', href: "https://linkedin.com/in/#{user.linkedin}")
      when 'x'
        expect(rendered).to have_link('X', href: "https://x.com/#{user.x}")
      when 'youtube'
        expect(rendered).to have_link('YouTube', href: "https://youtube.com/#{user.youtube}")
      when 'facebook'
        expect(rendered).to have_link('Facebook', href: "https://facebook.com/#{user.facebook}")
      when 'tiktok'
        expect(rendered).to have_link('TikTok', href: "https://tiktok.com/@#{user.tiktok}")
      end
    end
  end

  def expect_no_social_media_section
    expect(rendered).not_to have_content('CONNECT')
    expect(rendered).not_to have_css('.social-media, [class*="social"]')
  end

  # Avatar testing helpers
  def expect_avatar_image(user, size: nil)
    if user.avatar.attached?
      expect(rendered).to have_css("img[src*='#{user.avatar.filename}']")
      expect(rendered).to have_css("img[alt='#{user.first_name}']") if user.first_name.present?
    else
      expect_default_avatar_svg
    end
  end

  def expect_default_avatar_svg
    expect(rendered).to have_css('svg', count: 1)
    expect(rendered).to have_css('.bg-gradient-to-br')
  end

  # Action button testing
  def expect_agreement_button(current_user, person, project_id = nil)
    if current_user != person && project_id.present?
      expect(rendered).to have_link('Initiate Agreement',
        href: new_agreement_path(project_id:, other_party_id: person.id))
    else
      expect(rendered).not_to have_link('Initiate Agreement')
    end
  end

  def expect_message_button(current_user, person)
    if current_user != person
      expect(rendered).to have_button('Message')
      expect(rendered).to have_css("form[action='#{conversations_path}']")
      expect(rendered).to have_css("input[name='recipient_id'][value='#{person.id}']", visible: false)
    else
      expect(rendered).not_to have_button('Message')
    end
  end

  def expect_edit_profile_link(current_user, person)
    if current_user == person
      expect(rendered).to have_link('Edit Profile', href: profile_edit_path)
    else
      expect(rendered).not_to have_link('Edit Profile')
    end
  end

  # Connection analysis testing
  def expect_connection_analysis(current_user, person)
    return if current_user == person

    expect(rendered).to have_content("You and #{person.first_name}")

    # Check for connection content
    if has_shared_projects?(current_user, person) ||
       has_shared_skills?(current_user, person) ||
       has_shared_agreements?(current_user, person)
      expect(rendered).to have_css('.text-indigo-800') # Connection items
    else
      expect(rendered).to have_content('No direct connections yet')
    end
  end

  def has_shared_projects?(user1, user2)
    (user1.projects & user2.projects).any?
  end

  def has_shared_skills?(user1, user2)
    return false unless user1.try(:skills) && user2.try(:skills)
    (user1.skills & user2.skills).any?
  end

  def has_shared_agreements?(user1, user2)
    user1.all_agreements.joins(:agreement_participants)
         .where(agreement_participants: { user_id: user2.id }).exists?
  end

  # Stats card testing
  def expect_stats_cards(presenter)
    expect(rendered).to have_content('Member Since')
    expect(rendered).to have_content(presenter.member_since)

    expect(rendered).to have_content('Projects')
    expect(rendered).to have_content(presenter.projects_count)

    expect(rendered).to have_content('Agreements')
    expect(rendered).to have_content(presenter.agreements_count)
  end

  # Navigation tabs testing
  def expect_navigation_tabs(current_user, person)
    %w[About Achievements Track\ Record Projects].each do |tab|
      expect(rendered).to have_link(tab, href: "##{tab.downcase.gsub(' ', '')}")
    end

    if current_user == person
      expect(rendered).to have_link('Edit Profile', href: profile_edit_path)
    end
  end

  # Section testing helpers
  def expect_about_section(presenter, current_user, person)
    expect(rendered).to have_content('About')

    if presenter.formatted_bio
      expect(rendered).to have_content(presenter.formatted_bio)
    elsif current_user == person
      expect(rendered).to have_link('Add a bio', href: edit_profile_path)
    else
      expect(rendered).to have_content('No bio provided yet')
    end
  end

  def expect_achievements_section
    expect(rendered).to have_content('Achievements')
    expect(rendered).to render_template(partial: 'shared/_achievements')
  end

  def expect_track_record_section(person)
    expect(rendered).to have_content('Track Record')
    expect(rendered).to render_template(partial: 'shared/_track_record')
  end

  def expect_projects_section(projects)
    expect(rendered).to have_content('Projects Involved In')

    if projects.any?
      projects.uniq.each do |project|
        expect(rendered).to have_link(project.name, href: project_path(project))
        expect(rendered).to have_content("Stage: #{project.stage.capitalize}")
        expect(rendered).to have_content("Created #{time_ago_in_words(project.created_at)} ago")
      end
    else
      expect(rendered).to have_content('No projects found for this user')
    end
  end

  # Call-to-action testing
  def expect_collaboration_cta(current_user, person)
    return if current_user == person

    expect(rendered).to have_content("Interested in collaborating with #{person.first_name}?")
    expect(rendered).to have_button('Send Message')
    expect(rendered).to have_css("form[action='#{conversations_path}']")
  end

  # Accessibility testing helpers
  def expect_accessible_images
    # All images should have alt text
    expect(rendered).not_to have_css('img:not([alt])')

    # Avatar images should have meaningful alt text
    expect(rendered).to have_css('img[alt]') if rendered.match?(/img/)
  end

  def expect_accessible_links
    # All links should have accessible text or aria-label
    expect(rendered).not_to have_css('a:empty:not([aria-label])')

    # External links should indicate they open in new window
    rendered.scan(/target="_blank"/).each do |_match|
      expect(rendered).to have_css('svg') # Should have external link icon
    end
  end

  def expect_accessible_forms
    # Form elements should have labels or aria-label
    expect(rendered).not_to have_css('input:not([aria-label]):not([id])')
    expect(rendered).not_to have_css('button:empty:not([aria-label])')
  end

  def expect_semantic_html
    # Check for proper heading hierarchy
    expect(rendered).to have_css('h1')

    # Sections should be properly marked up
    expect(rendered).to have_css('section') if rendered.include?('section')
  end

  # Mobile responsiveness testing
  def expect_responsive_design
    # Should have responsive classes
    expect(rendered).to match(/sm:|md:|lg:|xl:/)

    # Grid should be responsive
    expect(rendered).to have_css('.grid-cols-1') if rendered.include?('grid')

    # Flex containers should be responsive
    expect(rendered).to match(/flex-col.*lg:flex-row|flex-wrap/) if rendered.include?('flex')
  end

  # Performance testing helpers
  def expect_optimized_images
    # Images should have proper sizing classes
    if rendered.include?('image_tag')
      expect(rendered).to have_css('img[class*="w-"]')
      expect(rendered).to have_css('img[class*="h-"]')
    end
  end

  def expect_minimal_inline_styles
    # Should prefer CSS classes over inline styles
    inline_styles = rendered.scan(/style="[^"]*"/).size
    expect(inline_styles).to be <= 2 # Allow minimal inline styles
  end
end

RSpec.configure do |config|
  config.include ViewHelpers, type: :view
  config.include ViewHelpers, type: :system
end
