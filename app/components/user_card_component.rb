# frozen_string_literal: true

class UserCardComponent < ApplicationComponent
  def initialize(
    user:,
    current_user: nil,
    show_message_button: nil,
    show_stats: true,
    show_skills: true,
    propose_for_project: nil,
    compact: false
  )
    @user = user
    @current_user = current_user
    @show_message_button = show_message_button.nil? ? (user != current_user) : show_message_button
    @show_stats = show_stats
    @show_skills = show_skills
    @propose_for_project = propose_for_project
    @compact = compact
  end

  def render?
    @user.present?
  end

  def call
    link_to(user_path, class: card_classes, data: { turbo_frame: "_top" }) do
      safe_join([
        render_header_section,
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
    base = "block bg-base-100 border border-base-300 rounded-xl shadow-sm cursor-pointer group hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 no-underline"
    @compact ? "#{base} p-3" : base
  end

  def render_header_section
    tag.div(class: header_classes) do
      safe_join([
        render(Ui::AvatarComponent.new(user: @user, size: avatar_size, placeholder: :initials)),
        render_name_section
      ])
    end
  end

  def header_classes
    @compact ? "flex items-center gap-3" : "flex items-center gap-3 p-4 pb-0"
  end

  def avatar_size
    @compact ? :sm : :lg
  end

  def render_name_section
    tag.div(class: "flex-1 min-w-0") do
      safe_join([
        tag.h3(@user.full_name, class: name_classes),
        render_member_badge
      ].compact)
    end
  end

  def name_classes
    @compact ? "text-sm font-semibold text-base-content truncate" : "text-base font-bold text-base-content truncate"
  end

  def render_member_badge
    return nil if @compact

    tag.span("Member", class: "badge badge-ghost badge-xs mt-0.5")
  end

  def render_content_section
    return nil if @compact

    tag.div(class: "p-4 pt-3") do
      safe_join([
        render_bio,
        render_skills,
        render_stats
      ].compact)
    end
  end

  def render_bio
    return nil if @compact

    bio_text = @user.bio.presence || "Ready to collaborate."
    tag.p(bio_text, class: "text-sm text-base-content/60 line-clamp-2 mb-2")
  end

  def render_skills
    return nil unless @show_skills && user_skills.any?
    return nil if @compact

    tag.div(class: "flex flex-wrap gap-1 mb-2") do
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
      tag.span(skill, class: "badge badge-sm badge-ghost")
    end)
  end

  def render_more_skills_badge
    return nil unless user_skills.count > 3

    tag.span("+#{user_skills.count - 3}", class: "badge badge-sm badge-ghost")
  end

  def render_stats
    return nil unless @show_stats
    return nil if @compact

    tag.div(class: "flex items-center gap-3 text-xs text-base-content/60") do
      safe_join([
        render_stat(projects_count, "projects"),
        render_stat(collaborations_count, "collabs")
      ])
    end
  end

  def render_stat(count, label)
    tag.span("#{count} #{label}")
  end

  def projects_count
    @user.respond_to?(:projects) ? @user.projects.count : 0
  end

  def collaborations_count
    return 0 unless @user.respond_to?(:all_agreements)

    @user.all_agreements.where(status: "accepted").count
  end

  def render_footer_section
    return render_compact_footer if @compact

    tag.div(class: "border-t border-base-200 px-4 py-2 flex items-center justify-between") do
      safe_join([
        tag.span("View", class: "text-xs font-medium text-primary group-hover:underline"),
        render_connect_button
      ].compact)
    end
  end

  def render_compact_footer
    return nil unless render_connect_button

    tag.div(class: "mt-2 flex justify-end") do
      render_connect_button
    end
  end

  def render_connect_button
    return nil unless @current_user && @user != @current_user

    if @propose_for_project
      render_propose_button
    elsif @show_message_button
      render_message_button
    end
  end

  def render_propose_button
    helpers.link_to(
      helpers.new_agreement_path(project_id: @propose_for_project.id, other_party_id: @user.id),
      onclick: "event.stopPropagation();",
      class: "btn btn-success btn-xs gap-1"
    ) do
      safe_join([
        render(Ui::IconComponent.new(name: :plus, size: :xs)),
        "Propose"
      ])
    end
  end

  def render_message_button
    helpers.button_to(
      "Connect",
      helpers.conversations_path,
      params: { recipient_id: @user.id },
      method: :post,
      data: { turbo: false },
      class: "btn btn-primary btn-xs"
    )
  end
end
