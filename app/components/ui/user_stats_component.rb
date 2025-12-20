# frozen_string_literal: true

module Ui
  class UserStatsComponent < ApplicationComponent
    VARIANTS = {
      horizontal: { wrapper: "stats stats-vertical sm:stats-horizontal shadow w-full", stat: "stat" },
      compact: { wrapper: "flex flex-wrap gap-4 text-sm", stat: "flex items-center gap-2" },
      inline: { wrapper: "flex flex-wrap gap-3 text-sm text-base-content/70", stat: "flex items-center gap-1" }
    }.freeze

    STAT_ICONS = {
      projects: "M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z",
      agreements: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
      member_since: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z",
      rating: "M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
    }.freeze

    STAT_COLORS = {
      projects: "text-primary",
      agreements: "text-secondary",
      member_since: "text-info",
      rating: "text-warning"
    }.freeze

    def initialize(user:, variant: :horizontal, show_icons: true, show_rating: false, presenter: nil, current_user: nil, interactive_rating: false)
      @user = user
      @variant = variant.to_sym
      @show_icons = show_icons
      @show_rating = show_rating
      @presenter = presenter
      @current_user = current_user
      @interactive_rating = interactive_rating
    end

    def call
      tag.div(class: variant_config[:wrapper]) do
        safe_join(stats_to_render)
      end
    end

    def render?
      @user.present?
    end

    private

    def variant_config
      VARIANTS[@variant] || VARIANTS[:horizontal]
    end

    def presenter
      @presenter ||= helpers.respond_to?(:present) ? helpers.present(@user) : build_fallback_presenter
    end

    def build_fallback_presenter
      UserStatsPresenter.new(
        projects_count: helpers.pluralize(@user.projects.count, "project"),
        agreements_count: helpers.pluralize(@user.all_agreements.count, "agreement"),
        member_since: "Member since #{@user.created_at.strftime('%B %Y')}"
      )
    end

    def stats_to_render
      stats = [
        render_stat(:projects, presenter.projects_count, "Projects"),
        render_stat(:agreements, presenter.agreements_count, "Agreements"),
        render_stat(:member_since, member_since_value, "Member Since")
      ]
      stats << render_rating_stat if @show_rating
      stats.compact
    end

    def member_since_value
      if @variant == :horizontal
        presenter.member_since
      else
        @user.created_at.strftime("%b %Y")
      end
    end

    def render_stat(type, value, label)
      case @variant
      when :horizontal
        render_horizontal_stat(type, value, label)
      when :compact
        render_compact_stat(type, value)
      when :inline
        render_inline_stat(type, value)
      end
    end

    def render_horizontal_stat(type, value, label)
      tag.div(class: variant_config[:stat]) do
        safe_join([
          render_stat_figure(type),
          tag.div(label, class: "stat-title"),
          tag.div(extract_value(value), class: "stat-value #{stat_value_size}"),
          render_stat_desc(type)
        ])
      end
    end

    def render_compact_stat(type, value)
      tag.div(class: variant_config[:stat]) do
        safe_join([
          (@show_icons ? render_icon(type, "h-4 w-4") : "".html_safe),
          tag.span(value, class: "font-medium")
        ])
      end
    end

    def render_inline_stat(type, value)
      tag.span(class: variant_config[:stat]) do
        safe_join([
          (@show_icons ? render_icon(type, "h-3 w-3") : "".html_safe),
          value.to_s
        ])
      end
    end

    def render_stat_figure(type)
      return "".html_safe unless @show_icons

      tag.div(class: "stat-figure #{STAT_COLORS[type]}") do
        render_icon(type, "h-8 w-8")
      end
    end

    def render_icon(type, size_class)
      path = STAT_ICONS[type]
      return "".html_safe unless path

      tag.svg(class: "#{size_class} #{STAT_COLORS[type]}", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: path)
      end
    end

    def render_stat_desc(type)
      return "".html_safe unless type == :projects

      tag.div(presenter.member_since, class: "stat-desc")
    end

    def render_rating_stat
      return unless @show_rating

      tag.div(class: variant_config[:stat]) do
        safe_join([
          render_stat_figure(:rating),
          tag.div("Community Rating", class: "stat-title"),
          tag.div(class: "stat-value") do
            render_star_rating_display
          end,
          render_rating_breakdown
        ])
      end
    end

    def render_star_rating_display
      # Use interactive partial if enabled and current_user is available
      if @interactive_rating && @current_user
        render("ratings/rating_display", user: @user, current_user: @current_user, show_controls: true)
      else
        render_readonly_star_display
      end
    end

    def render_readonly_star_display
      rating_value = user_rating
      review_count = user_review_count

      tag.div(
        id: "user_#{@user.id}_rating",
        class: "star-rating-container relative inline-flex items-center gap-3",
        data: {
          controller: "star-rating",
          star_rating_rating_value: rating_value,
          star_rating_max_rating_value: 5,
          star_rating_readonly_value: true,
          star_rating_animated_value: true
        }
      ) do
        safe_join([
          render_stars_wrapper,
          render_rating_value_badge(rating_value),
          render_rating_tooltip(rating_value, review_count)
        ])
      end
    end

    def render_stars_wrapper
      tag.div(
        class: "flex items-center gap-0.5",
        data: { action: "mouseenter->star-rating#mouseEnter mouseleave->star-rating#mouseLeave" }
      ) do
        safe_join(5.times.map { |i| render_single_star(i + 1) })
      end
    end

    def render_single_star(position)
      tag.div(
        class: "star-wrapper relative cursor-default transition-transform duration-200",
        data: {
          star_rating_target: "star",
          star_index: position,
          action: "mouseenter->star-rating#starMouseEnter mouseleave->star-rating#starMouseLeave"
        }
      ) do
        safe_join([
          render_empty_star,
          render_filled_star
        ])
      end
    end

    def render_empty_star
      tag.svg(
        class: "w-6 h-6 text-base-content/20",
        viewBox: "0 0 24 24",
        fill: "currentColor",
        data: { star_empty: true }
      ) do
        tag.path(d: star_svg_path)
      end
    end

    def render_filled_star
      tag.svg(
        class: "w-6 h-6 text-warning absolute inset-0 transition-all duration-300",
        viewBox: "0 0 24 24",
        fill: "currentColor",
        style: "clip-path: inset(0 0% 0 0);",
        data: { star_filled: true }
      ) do
        tag.path(d: star_svg_path)
      end
    end

    def star_svg_path
      "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
    end

    def render_rating_value_badge(rating_value)
      display_value = rating_value.positive? ? rating_value.to_s : "-"

      tag.div(class: "flex items-center gap-1.5") do
        safe_join([
          tag.span(
            display_value,
            class: "text-2xl font-bold text-warning",
            data: { star_rating_target: "value" }
          ),
          tag.span("/5", class: "text-sm text-base-content/50")
        ])
      end
    end

    def render_rating_tooltip(rating_value, review_count)
      tooltip_text = if review_count.positive?
                       "#{rating_value} out of 5"
      else
                       "No ratings yet"
      end

      tag.div(
        class: "absolute -top-12 left-1/2 -translate-x-1/2 bg-neutral text-neutral-content " \
               "px-3 py-2 rounded-lg shadow-lg opacity-0 invisible transition-all duration-200 " \
               "whitespace-nowrap z-50",
        data: { star_rating_target: "tooltip" }
      ) do
        safe_join([
          tag.div(class: "flex items-center gap-2 text-sm") do
            if review_count.positive?
              safe_join([
                tag.span(tooltip_text, class: "font-medium"),
                tag.span("\u2022", class: "text-neutral-content/50"),
                tag.span(helpers.pluralize(review_count, "review"), class: "text-neutral-content/70")
              ])
            else
              tag.span(tooltip_text, class: "font-medium")
            end
          end,
          tag.div(class: "absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-neutral rotate-45")
        ])
      end
    end

    def render_rating_breakdown
      review_count = user_review_count

      tag.div(class: "stat-desc flex items-center gap-2 mt-1") do
        if review_count.positive?
          safe_join([
            tag.span(helpers.pluralize(review_count, "review"), class: "text-base-content/60")
          ])
        else
          tag.span("Be the first to rate!", class: "text-base-content/60 italic")
        end
      end
    end

    def user_rating
      @user.average_rating
    end

    def user_review_count
      @user.rating_count
    end

    def stat_value_size
      @variant == :horizontal ? "text-primary" : ""
    end

    def extract_value(value)
      # Extract just the number if it's a string like "5 projects"
      value.to_s.split.first || value
    end
  end
end
