# frozen_string_literal: true

module Users
  class ProfileHeaderComponent < ApplicationComponent
    def initialize(
      person:,
      current_user:,
      shared_agreements_count: 0,
      show_stats: true,
      show_social: true,
      show_affinity: true
    )
      @person = person
      @current_user = current_user
      @shared_agreements_count = shared_agreements_count
      @show_stats = show_stats
      @show_social = show_social
      @show_affinity = show_affinity
    end

    def call
      tag.div(class: "card bg-base-100 shadow-xl") do
        tag.div(class: "card-body") do
          safe_join([
            render_main_content,
            render_stats_section,
            render_social_section,
            render_affinity_section
          ].compact)
        end
      end
    end

    def render?
      @person.present?
    end

    private

    def presenter
      @presenter ||= begin
        if helpers.respond_to?(:present)
          helpers.present(@person) || fallback_presenter
        else
          fallback_presenter
        end
      rescue StandardError
        fallback_presenter
      end
    end

    def fallback_presenter
      OpenStruct.new(
        display_name: @person.full_name,
        badges: "",
        formatted_bio: nil,
        member_since: "",
        projects_count: "",
        agreements_count: ""
      )
    end

    def viewing_own_profile?
      @current_user == @person
    end

    def render_main_content
      tag.div(class: "flex flex-col lg:flex-row items-center lg:items-start gap-6") do
        safe_join([
          render_avatar,
          render_profile_info
        ])
      end
    end

    def render_avatar
      tag.div(class: "flex-shrink-0") do
        render(Ui::AvatarComponent.new(user: @person, size: :xxl, ring: true))
      end
    end

    def render_profile_info
      tag.div(class: "flex-1 w-full") do
        tag.div(class: "flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4") do
          safe_join([
            render_name_and_badges,
            render_action_buttons
          ])
        end
      end
    end

    def render_name_and_badges
      tag.div(class: "text-center lg:text-left") do
        safe_join([
          tag.h1(presenter.display_name, class: "text-3xl font-bold mb-2"),
          tag.div(class: "flex flex-wrap justify-center lg:justify-start gap-2") do
            presenter.badges
          end
        ])
      end
    end

    def render_action_buttons
      tag.div(class: "flex flex-col sm:flex-row gap-3") do
        safe_join([
          render_agreement_button,
          render_message_or_edit_button
        ].compact)
      end
    end

    def render_agreement_button
      return unless !viewing_own_profile? && @current_user.selected_project_id.present?

      helpers.link_to(
        helpers.new_agreement_path(project_id: @current_user.selected_project_id, other_party_id: @person.id),
        class: "btn btn-primary gap-2"
      ) do
        safe_join([
          render_plus_icon,
          "Initiate Agreement"
        ])
      end
    end

    def render_plus_icon
      tag.svg(class: "h-4 w-4", fill: "currentColor", viewBox: "0 0 20 20") do
        tag.path(
          "fill-rule": "evenodd",
          "clip-rule": "evenodd",
          d: "M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z"
        )
      end
    end

    def render_message_or_edit_button
      if viewing_own_profile?
        helpers.link_to("Edit Profile", helpers.profile_edit_path, class: "btn btn-ghost gap-2")
      else
        helpers.button_to(
          "Message",
          helpers.conversations_path(recipient_id: @person.id),
          method: :post,
          data: { turbo: false },
          class: "btn btn-success gap-2"
        )
      end
    end

    def render_stats_section
      return unless @show_stats

      tag.div(class: "mt-6") do
        render(Ui::UserStatsComponent.new(
          user: @person,
          variant: :horizontal,
          show_rating: true,
          presenter: presenter,
          current_user: @current_user,
          interactive_rating: !viewing_own_profile?
        ))
      end
    end

    def render_social_section
      return unless @show_social && social_links_present?

      tag.div(class: "mt-6") do
        render(Ui::SocialLinksComponent.new(
          user: @person,
          variant: :buttons,
          show_header: true,
          header_text: "CONNECT"
        ))
      end
    end

    def social_links_present?
      %i[linkedin x instagram youtube facebook tiktok github].any? do |platform|
        @person.respond_to?(platform) && @person.send(platform).present?
      end
    end

    def render_affinity_section
      return unless @show_affinity && !viewing_own_profile?

      shared_projects = (@current_user.projects & @person.projects)
      shared_skills = fetch_shared_skills

      return unless shared_projects.any? || shared_skills.any? || @shared_agreements_count.positive?

      tag.div(class: "mt-6 bg-secondary/10 border border-secondary/20 rounded-box p-4") do
        safe_join([
          render_affinity_header,
          render_affinity_content(shared_projects, shared_skills)
        ])
      end
    end

    def fetch_shared_skills
      current_skills = @current_user.try(:skills) || []
      person_skills = @person.try(:skills) || []
      current_skills & person_skills
    end

    def render_affinity_header
      tag.h3(class: "text-sm font-bold text-secondary mb-3 flex items-center") do
        safe_join([
          render_lightning_icon,
          "You and #{@person.first_name}"
        ])
      end
    end

    def render_lightning_icon
      tag.svg(class: "h-4 w-4 mr-2", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M13 10V3L4 14h7v7l9-11h-7z"
        )
      end
    end

    def render_affinity_content(shared_projects, shared_skills)
      tag.div(class: "space-y-2") do
        safe_join([
          render_shared_projects(shared_projects),
          render_shared_skills(shared_skills),
          render_shared_agreements
        ].compact)
      end
    end

    def render_shared_projects(shared_projects)
      return unless shared_projects.any?

      render_affinity_item(
        "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10",
        "Shared projects:",
        shared_projects.map(&:name).join(", ")
      )
    end

    def render_shared_skills(shared_skills)
      return unless shared_skills.any?

      render_affinity_item(
        "M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z",
        "Shared skills:",
        shared_skills.join(", ")
      )
    end

    def render_shared_agreements
      return unless @shared_agreements_count.positive?

      render_affinity_item(
        "M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z",
        "Active agreements:",
        helpers.pluralize(@shared_agreements_count, "collaboration")
      )
    end

    def render_affinity_item(icon_path, label, value)
      tag.div(class: "flex items-center text-sm") do
        safe_join([
          tag.svg(class: "h-4 w-4 mr-2 text-secondary", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
            tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: icon_path)
          end,
          tag.span(label, class: "font-medium"),
          " #{value}"
        ])
      end
    end
  end
end
