# frozen_string_literal: true

class ProjectCardComponent < ApplicationComponent
  def initialize(project:, current_user: nil, variant: :grid, presenter: nil)
    @project = project
    @current_user = current_user
    @variant = variant.to_sym
    @presenter = presenter
  end

    def render?
      @project.present?
    end

    def call
      case @variant
      when :list
        render_list_variant
      when :compact
        render_compact_variant
      else
        render_grid_variant
      end
    end

    private

    def presenter
      @presenter ||= helpers.present(@project)
    end

    # Grid variant (used in explore projects)
    def render_grid_variant
      helpers.link_to helpers.project_path(@project), 
                      class: "card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-[1.02] group overflow-hidden h-full",
                      style: "text-decoration: none; color: inherit; display: block;",
                      data: { turbo_frame: "_top" } do
        tag.div(class: "card-body") do
          safe_join([
            grid_header,
            grid_description,
            grid_owner_info,
            grid_footer
          ])
        end
      end
    end

    def grid_header
      tag.div(class: "flex justify-between items-start mb-4") do
        safe_join([
          tag.h3(class: "card-title text-base-content group-hover:text-primary transition-colors duration-200") do
            presenter.display_name(@current_user)
          end,
          tag.div(class: "flex flex-col items-end space-y-2") do
            safe_join([
              presenter.stage_badge,
              presenter.collaboration_badges,
              presenter.funding_status_badge
            ].compact)
          end
        ])
      end
    end

    def grid_description
      tag.p(presenter.display_description(@current_user, truncate: true, length: 120), 
            class: "text-sm text-base-content/60 line-clamp-3 mb-4")
    end

    def grid_owner_info
      tag.div(class: "flex items-center mb-4") do
        safe_join([
          tag.div(class: "flex-shrink-0") do
            render(Ui::AvatarComponent.new(user: @project.user, size: :sm, placeholder: :initials))
          end,
          tag.div(class: "ml-4") do
            safe_join([
              tag.p(presenter.owner_display, class: "text-sm font-semibold text-base-content"),
              tag.p(presenter.created_timeframe, class: "text-xs text-base-content/60")
            ])
          end
        ])
      end
    end

    def grid_footer
      tag.div(class: "flex items-center justify-between pt-4 border-t border-base-200 group-hover:border-primary/30 transition-colors duration-200 mt-auto") do
        safe_join([
          tag.span("View Details", class: "text-sm font-semibold text-primary group-hover:text-primary-focus transition-colors duration-200"),
          tag.svg(class: "w-5 h-5 text-primary group-hover:text-primary-focus group-hover:translate-x-1 transition-all duration-200", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
            tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M17 8l4 4m0 0l-4 4m4-4H3")
          end
        ])
      end
    end

    # List variant (used in dashboard recent projects)
    def render_list_variant
      tag.li(class: "group", data: { controller: "project-card", project_card_url_value: helpers.project_path(@project) }) do
        tag.div(class: list_classes, data: { action: "click->project-card#navigate", turbo_frame: "_top" }) do
          safe_join([
            list_header,
            list_description,
            list_stats
          ])
        end
      end
    end

    def list_classes
      "p-4 rounded-xl bg-gradient-to-r from-base-100/80 to-base-200/30 hover:from-primary/10 hover:to-secondary/10 border border-base-300/50 hover:border-primary/50 transition-all duration-300 hover:shadow-lg interactive-card cursor-pointer"
    end

    def list_header
      tag.div(class: "flex items-start justify-between mb-3") do
        safe_join([
          tag.div(class: "flex-1 min-w-0") do
            safe_join([
              tag.h3(class: "truncate text-base font-semibold text-base-content group-hover:text-primary transition-colors duration-200") do
                presenter.display_name(@current_user)
              end,
              tag.p(class: "mt-1 text-xs text-base-content/60 flex items-center flex-wrap gap-x-3") do
                safe_join([
                  tag.span("Updated #{helpers.time_ago_in_words(@project.updated_at)} ago"),
                  render_github_activity_indicator
                ].compact)
              end
            ])
          end,
          presenter.stage_badge
        ])
      end
    end

    def list_description
      tag.div(class: "mb-4") do
        tag.p(presenter.display_description(@current_user, truncate: true, length: 120), 
              class: "text-sm text-base-content/70 line-clamp-2 leading-relaxed")
      end
    end

    def list_stats
      tag.div(class: "flex items-center justify-between pt-3 border-t border-base-300/50") do
        safe_join([
          tag.div(class: "flex items-center space-x-4 text-xs text-base-content/60") do
            safe_join([
              render_owner_mini_avatar,
              render_milestones_stat,
              render_agreements_stat
            ])
          end,
          tag.svg(class: "h-4 w-4 text-base-content/40 opacity-0 group-hover:opacity-100 transition-opacity duration-200", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
            tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9 5l7 7-7 7")
          end
        ])
      end
    end

    # Compact variant (used in dashboard explorable section)
    def render_compact_variant
      tag.div(class: "card card-compact bg-base-200 hover:shadow-md transition-shadow h-full") do
        tag.div(class: "card-body") do
          safe_join([
            tag.div(class: "flex items-start justify-between gap-2") do
              safe_join([
                tag.h3(presenter.display_name(@current_user), class: "font-medium text-sm truncate"),
                presenter.stage_badge
              ])
            end,
            tag.p(presenter.display_description(@current_user, truncate: true), class: "text-xs text-base-content/60 line-clamp-2"),
            tag.div(class: "flex items-center justify-between mt-2 pt-2 border-t border-base-300 mt-auto") do
              safe_join([
                tag.div(class: "flex items-center gap-2") do
                  safe_join([
                    render(Ui::AvatarComponent.new(user: @project.user, size: :xs, placeholder: :initials)),
                    tag.span(@project.user.first_name, class: "text-xs text-base-content/60")
                  ])
                end,
                helpers.link_to("View", helpers.project_path(@project), class: "btn btn-primary btn-xs")
              ])
            end
          ])
        end
      end
    end

    # Helpers
    def render_owner_mini_avatar
      helpers.link_to(
        helpers.person_path(@project.user),
        onclick: "event.stopPropagation();",
        class: "flex items-center gap-1.5 hover:text-primary transition-colors"
      ) do
        safe_join([
          render(Ui::AvatarComponent.new(user: @project.user, size: :xs, placeholder: :initials)),
          tag.span(@project.user.full_name, class: "truncate max-w-[80px]")
        ])
      end
    end

    def render_milestones_stat
      tag.div(class: "flex items-center") do
        safe_join([
          tag.svg(class: "h-3 w-3 mr-1 text-base-content/40", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
            tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2")
          end,
          tag.span(presenter.milestones_summary)
        ])
      end
    end

    def render_agreements_stat
      tag.div(class: "flex items-center") do
        safe_join([
          tag.svg(class: "h-3 w-3 mr-1 text-base-content/40", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
            tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z")
          end,
          tag.span(helpers.pluralize(@project.agreements.count, "agreement"))
        ])
      end
    end

    def render_github_activity_indicator
      return nil unless @project.github_connected?
      activity = @project.activity_level
      return nil if activity == :none

      dot_color = case activity
      when :active then "bg-success"
      when :moderate then "bg-warning"
      else "bg-base-content/30"
      end

      tag.span(class: "flex items-center gap-1.5") do
        safe_join([
          tag.span(class: "h-2 w-2 rounded-full #{dot_color}"),
          tag.span("GitHub Active", class: "text-xs")
        ])
          end
        end
      end