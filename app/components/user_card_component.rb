# frozen_string_literal: true

class UserCardComponent < ApplicationComponent
  def initialize(
    user:,
    current_user: nil,
    avatar_height: "h-40",
    show_message_button: nil,
    show_stats: true,
    show_skills: true
  )
    @user = user
    @current_user = current_user
    @avatar_height = avatar_height
    @show_message_button = show_message_button.nil? ? (user != current_user) : show_message_button
    @show_stats = show_stats
    @show_skills = show_skills
  end

  def render?
    @user.present?
  end

  def call
    link_to(user_path, class: card_classes, data: { turbo_frame: "_top" }) do
      safe_join([
        render_avatar_section,
        render_content_section,
        render_footer_section
      ])
    end
  end

  private

  def user_path
    @user.id ? helpers.person_path(@user) : "#"
  end

  def card_classes
    "block bg-white/80 backdrop-blur-sm border border-white/30 rounded-2xl shadow-lg cursor-pointer group relative hover:shadow-xl hover:-translate-y-1 transition-all duration-300 no-underline"
  end

  def render_avatar_section
    tag.div(class: "#{@avatar_height} bg-gradient-to-br from-primary/20 to-secondary/20 rounded-t-2xl flex items-center justify-center relative overflow-hidden") do
      if @user.respond_to?(:avatar) && @user.avatar.attached?
        safe_join([
          helpers.image_tag(@user.avatar, class: "h-full w-full object-cover"),
          tag.div(class: "absolute inset-0 bg-gradient-to-t from-black/10 to-transparent")
        ])
      else
        render_default_avatar
      end
    end
  end

  def render_default_avatar
    tag.svg(class: "h-16 w-16 text-primary/30", fill: "currentColor", viewBox: "0 0 24 24") do
      tag.path(d: "M24 20.993V24H0v-2.996A14.977 14.977 0 0112.004 15c4.904 0 9.26 2.354 11.996 5.993zM16.002 8.999a4 4 0 11-8 0 4 4 0 018 0z")
    end
  end

  def render_content_section
    tag.div(class: "p-5") do
      safe_join([
        render_header,
        render_bio,
        render_skills,
        render_stats
      ].compact)
    end
  end

  def render_header
    tag.div(class: "flex items-start justify-between mb-3") do
      tag.div(class: "flex-1 min-w-0") do
        safe_join([
          tag.h3(@user.full_name, class: "text-lg font-bold text-base-content truncate"),
          tag.span("Community Person", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gradient-to-r from-primary/20 to-secondary/20 text-primary border border-primary/30 mt-1")
        ])
      end
    end
  end

  def render_bio
    bio_text = @user.bio.presence || "Passionate member of the FlukeBase community, ready to collaborate and grow together."
    tag.p(bio_text, class: "text-sm text-base-content/70 line-clamp-2 mb-3 leading-relaxed")
  end

  def render_skills
    return nil unless @show_skills && user_skills.any?

    tag.div(class: "flex flex-wrap gap-1 mb-3") do
      safe_join([
        render_skill_badges,
        render_more_skills_badge
      ].compact)
    end
  end

  def user_skills
    @user_skills ||= @user.respond_to?(:skills) ? (@user.skills || []) : []
  end

  def render_skill_badges
    safe_join(user_skills.first(3).map do |skill|
      tag.span(skill, class: "inline-flex items-center px-2 py-1 rounded-lg text-xs font-medium bg-primary/10 text-primary border border-primary/20")
    end)
  end

  def render_more_skills_badge
    return nil unless user_skills.count > 3

    tag.span("+#{user_skills.count - 3} more", class: "inline-flex items-center px-2 py-1 rounded-lg text-xs font-medium bg-base-200 text-base-content/70")
  end

  def render_stats
    return nil unless @show_stats

    tag.div(class: "flex items-center justify-between text-xs text-base-content/60 mb-3") do
      safe_join([
        render_projects_stat,
        render_collaborations_stat
      ])
    end
  end

  def render_projects_stat
    tag.div(class: "flex items-center") do
      safe_join([
        render_projects_icon,
        helpers.pluralize(projects_count, "project")
      ])
    end
  end

  def projects_count
    @user.respond_to?(:projects) ? @user.projects.count : 0
  end

  def render_projects_icon
    tag.svg(class: "h-4 w-4 mr-1 text-primary", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
      tag.path(
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "stroke-width": "2",
        d: "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
      )
    end
  end

  def render_collaborations_stat
    tag.div(class: "flex items-center") do
      safe_join([
        render_collaborations_icon,
        helpers.pluralize(collaborations_count, "collaboration")
      ])
    end
  end

  def collaborations_count
    return 0 unless @user.respond_to?(:all_agreements)

    @user.all_agreements.where(status: "accepted").count
  end

  def render_collaborations_icon
    tag.svg(class: "h-4 w-4 mr-1 text-secondary", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
      tag.path(
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "stroke-width": "2",
        d: "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
      )
    end
  end

  def render_footer_section
    tag.div(class: "border-t border-base-300/50 px-5 py-3 flex items-center justify-between bg-gradient-to-r from-base-100/50 to-base-200/50 rounded-b-2xl") do
      safe_join([
        tag.span("View Profile", class: "text-sm font-semibold text-primary transition group-hover:text-primary-focus select-none"),
        render_connect_button
      ].compact)
    end
  end

  def render_connect_button
    return nil unless @show_message_button && @current_user

    helpers.button_to(
      "Connect",
      helpers.conversations_path,
      params: { recipient_id: @user.id },
      method: :post,
      data: { turbo: false },
      class: "cta-btn inline-flex items-center px-3 py-1.5 bg-gradient-to-r from-primary to-secondary text-primary-content text-xs font-semibold rounded-lg shadow-sm hover:brightness-110 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 transition-all duration-200 relative z-10"
    )
  end
end
