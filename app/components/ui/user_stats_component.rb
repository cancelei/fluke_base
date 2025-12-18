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

    def initialize(user:, variant: :horizontal, show_icons: true, show_rating: false, presenter: nil)
      @user = user
      @variant = variant.to_sym
      @show_icons = show_icons
      @show_rating = show_rating
      @presenter = presenter
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
      OpenStruct.new(
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
          tag.div(class: "stat-value flex items-center gap-2") do
            render_rating_stars
          end,
          tag.div("4.0 out of 5.0", class: "stat-desc")
        ])
      end
    end

    def render_rating_stars
      tag.div(class: "rating rating-md rating-half") do
        safe_join([
          tag.input(type: "radio", name: "rating-display", class: "rating-hidden"),
          *8.times.map { |i| rating_star_input(i) }
        ])
      end
    end

    def rating_star_input(index)
      half = index.even? ? "mask-half-1" : "mask-half-2"
      checked = index == 7 ? { checked: true } : {}
      tag.input(type: "radio", name: "rating-display", class: "mask mask-star-2 #{half} bg-warning", **checked)
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
