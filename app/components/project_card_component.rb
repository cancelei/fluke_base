# frozen_string_literal: true

class ProjectCardComponent < ApplicationComponent
  def initialize(project:, current_user: nil, presenter: nil)
    @project = project
    @current_user = current_user
    @presenter = presenter
  end

  def render?
    @project.present?
  end

  def call
    tag.li(class: "group") do
      tag.div(class: card_classes) do
        safe_join([
          render_header,
          render_description,
          render_stats
        ])
      end
    end
  end

  private

  def presenter
    @presenter ||= helpers.present(@project)
  end

  def card_classes
    "mx-4 my-3 p-4 rounded-xl bg-gradient-to-r from-base-100/80 to-base-200/30 hover:from-primary/10 hover:to-secondary/10 border border-base-300/50 hover:border-primary/50 transition-all duration-300 hover:shadow-lg hover:scale-[1.01] interactive-card"
  end

  def render_header
    tag.div(class: "flex items-start justify-between mb-3") do
      safe_join([
        render_title_section,
        render_stage_badge
      ])
    end
  end

  def render_title_section
    tag.div(class: "flex-1 min-w-0") do
      safe_join([
        tag.h3(class: "truncate text-base font-semibold text-base-content group-hover:text-primary transition-colors duration-200") do
          link_to(display_name, helpers.project_path(@project), class: "hover:underline focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-1 rounded")
        end,
        render_updated_time
      ])
    end
  end

  def display_name
    presenter.respond_to?(:display_name) ? presenter.display_name(@current_user) : @project.name
  end

  def render_updated_time
    tag.p(class: "mt-1 text-xs text-base-content/60 flex items-center") do
      safe_join([
        render_clock_icon,
        "Updated #{helpers.time_ago_in_words(@project.updated_at)} ago"
      ])
    end
  end

  def render_clock_icon
    tag.svg(class: "h-3 w-3 mr-1 text-base-content/40", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
      tag.path(
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "stroke-width": "2",
        d: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
      )
    end
  end

  def render_stage_badge
    tag.div(class: "ml-3 flex flex-shrink-0") do
      if presenter.respond_to?(:stage_badge)
        presenter.stage_badge
      else
        render(Ui::BadgeComponent.new(text: @project.stage || "unknown", status: @project.stage))
      end
    end
  end

  def render_description
    tag.div(class: "mb-4") do
      tag.p(description_text, class: "text-sm text-base-content/70 line-clamp-2 leading-relaxed")
    end
  end

  def description_text
    if presenter.respond_to?(:display_description)
      presenter.display_description(@current_user, truncate: true, length: 120)
    else
      helpers.truncate(@project.description.to_s, length: 120)
    end
  end

  def render_stats
    tag.div(class: "flex items-center justify-between pt-3 border-t border-base-300/50") do
      safe_join([
        render_stats_left,
        render_chevron
      ])
    end
  end

  def render_stats_left
    tag.div(class: "flex items-center space-x-4 text-xs text-base-content/60") do
      safe_join([
        render_milestones_stat,
        render_agreements_stat
      ])
    end
  end

  def render_milestones_stat
    tag.div(class: "flex items-center", title: "Project milestones") do
      safe_join([
        render_milestones_icon,
        tag.span(milestones_summary)
      ])
    end
  end

  def milestones_summary
    presenter.respond_to?(:milestones_summary) ? presenter.milestones_summary : "#{@project.milestones.count} milestones"
  end

  def render_milestones_icon
    tag.svg(class: "h-3 w-3 mr-1 text-base-content/40", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
      tag.path(
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "stroke-width": "2",
        d: "M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
      )
    end
  end

  def render_agreements_stat
    tag.div(class: "flex items-center", title: "Project agreements") do
      safe_join([
        render_agreements_icon,
        tag.span(helpers.pluralize(@project.agreements.count, "agreement"))
      ])
    end
  end

  def render_agreements_icon
    tag.svg(class: "h-3 w-3 mr-1 text-base-content/40", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
      tag.path(
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "stroke-width": "2",
        d: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
      )
    end
  end

  def render_chevron
    tag.div(class: "flex items-center") do
      tag.svg(class: "h-4 w-4 text-base-content/40 opacity-0 group-hover:opacity-100 transition-opacity duration-200", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M9 5l7 7-7 7"
        )
      end
    end
  end
end
