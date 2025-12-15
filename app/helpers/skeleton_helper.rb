# frozen_string_literal: true

# Helper methods for rendering skeleton loading states throughout the application.
#
# This helper provides convenient methods for using DaisyUI skeleton components
# to improve UX during content loading. It wraps the Ui::SkeletonComponent and
# Skeletons::* components for easier usage in views.
#
# @example Basic usage
#   <%= skeleton(:text) %>
#   <%= skeleton(:avatar, size: :lg) %>
#   <%= skeleton(:project_card) %>
#
# @example Grid of skeleton cards
#   <%= skeleton_grid(:project_card, count: 6) %>
#
# @example Table skeleton
#   <%= skeleton_table(rows: 5, columns: 4) %>
#
# @example With content loading container (uses Stimulus controller)
#   <%= skeleton_loader(variant: :project_card, count: 3) do %>
#     <%= render @projects %>
#   <% end %>
#
module SkeletonHelper
  # Render a single skeleton element
  #
  # @param variant [Symbol] The skeleton variant to render
  # @param options [Hash] Options passed to SkeletonComponent
  # @option options [Integer] :count Number of skeletons (default: 1)
  # @option options [String] :css_class Additional CSS classes
  # @option options [Symbol] :width Width modifier (:full, :half, :third, :quarter, :three_quarters)
  # @option options [Symbol] :animate Animation type (:default, :pulse, :wave, :none)
  # @option options [Symbol] :gap Gap between elements (:sm, :md, :lg)
  # @option options [Boolean] :stagger Apply staggered animation delays
  # @return [String] Rendered skeleton HTML
  def skeleton(variant, **options)
    render Ui::SkeletonComponent.new(variant: variant, **options)
  end

  # Render multiple skeleton elements of the same type
  #
  # @param variant [Symbol] The skeleton variant to render
  # @param count [Integer] Number of skeletons to render
  # @param options [Hash] Additional options
  # @return [String] Rendered skeletons HTML
  def skeleton_list(variant, count: 3, **options)
    render Ui::SkeletonComponent.new(variant: variant, count: count, **options)
  end

  # Render a grid of skeleton cards using the GridComponent
  #
  # @param variant [Symbol] The skeleton card variant (:project_card, :user_card, :agreement_card, etc.)
  # @param count [Integer] Number of skeleton cards
  # @param columns [Hash, Symbol] Responsive column configuration or preset (:projects, :users, :agreements)
  # @param gap [Symbol] Grid gap size
  # @param options [Hash] Additional options
  # @return [String] Rendered skeleton grid HTML
  def skeleton_grid(variant, count: 3, columns: :default, gap: :md, **options)
    render Skeletons::GridComponent.new(
      variant: variant,
      count: count,
      columns: columns,
      gap: gap,
      **options
    )
  end

  # Render a skeleton table using the TableComponent
  #
  # @param rows [Integer] Number of skeleton rows
  # @param columns [Integer] Number of columns per row
  # @param with_header [Boolean] Include table header skeleton
  # @param options [Hash] Additional options
  # @return [String] Rendered skeleton table HTML
  def skeleton_table(rows: 5, columns: 5, with_header: true, **options)
    render Skeletons::TableComponent.new(
      rows: rows,
      columns: columns,
      with_header: with_header,
      **options
    )
  end

  # Render a skeleton within a card container with optional title
  #
  # @param title [String] Optional loading title
  # @param description [String] Optional loading description
  # @param options [Hash] Container options
  # @yield Block content for the skeleton
  # @return [String] Rendered skeleton container HTML
  def skeleton_container(title: nil, description: nil, **options, &block)
    css_class = options.delete(:css_class) || options.delete(:class)
    variant = options.delete(:variant) || :default

    card_class = case variant
    when :elevated then "card bg-base-100 shadow-2xl"
    when :flat then "card bg-base-100 border border-base-300"
    when :minimal then "card bg-base-100 shadow-md"
    else "card bg-base-100 shadow-xl"
    end

    content_tag(:div, class: "#{card_class} #{css_class}", role: "status", "aria-label": "Loading") do
      content_tag(:div, class: "card-body") do
        parts = []

        if title.present?
          parts << content_tag(:div, class: "mb-4") do
            header_parts = []
            header_parts << content_tag(:h3, title, class: "card-title")
            header_parts << content_tag(:p, description, class: "text-sm opacity-70 mt-1") if description.present?
            safe_join(header_parts)
          end
        end

        parts << capture(&block) if block_given?
        safe_join(parts)
      end
    end
  end

  # Render a page loading skeleton using the PageComponent
  #
  # @param layout [Symbol] Page layout preset (:dashboard, :list, :grid, :detail, :form)
  # @param items [Integer] Number of items for lists/grids
  # @param options [Hash] Additional options
  # @return [String] Rendered page skeleton HTML
  def skeleton_page(layout: :dashboard, items: 5, **options)
    render Skeletons::PageComponent.new(layout: layout, items: items, **options)
  end

  # Render a stats skeleton using the StatsComponent
  #
  # @param count [Integer] Number of stat items
  # @param horizontal [Boolean] Display horizontally
  # @param options [Hash] Additional options
  # @return [String] Rendered stats skeleton HTML
  def skeleton_stats(count: 3, horizontal: true, **options)
    render Skeletons::StatsComponent.new(count: count, horizontal: horizontal, **options)
  end

  # Render a form skeleton using the FormComponent
  #
  # @param fields [Integer] Number of form fields
  # @param with_actions [Boolean] Show action buttons
  # @param options [Hash] Additional options
  # @return [String] Rendered form skeleton HTML
  def skeleton_form(fields: 4, with_actions: true, **options)
    render Skeletons::FormComponent.new(fields: fields, with_actions: with_actions, **options)
  end

  # Render a dashboard widget skeleton
  #
  # @param title [String] Optional widget title
  # @param items [Integer] Number of items
  # @param options [Hash] Additional options
  # @return [String] Rendered widget skeleton HTML
  def skeleton_widget(title: nil, items: 3, **options)
    render Skeletons::DashboardWidgetComponent.new(title: title, items: items, **options)
  end

  # Render a skeleton loader container with content
  # Uses the skeleton-loader Stimulus controller for smooth transitions
  #
  # @param variant [Symbol] Skeleton variant to show while loading
  # @param count [Integer] Number of skeleton items
  # @param layout [Symbol] Layout type (:grid, :list, :table, :single)
  # @param delay [Integer] Minimum display time in ms
  # @param options [Hash] Additional options
  # @yield Block containing the actual content
  # @return [String] Rendered skeleton loader HTML
  def skeleton_loader(variant: :card, count: 3, layout: :single, delay: 0, **options, &block)
    css_class = options.delete(:css_class) || options.delete(:class)

    content_tag(
      :div,
      class: class_names("skeleton-loader", css_class),
      data: {
        controller: "skeleton-loader",
        skeleton_loader_delay_value: delay,
        skeleton_loader_loaded_class: "skeleton-loaded"
      }
    ) do
      safe_join([
        render_skeleton_placeholder(variant, count, layout, options),
        content_tag(:div, data: { skeleton_loader_target: "content" }, class: "hidden", &block)
      ])
    end
  end

  # Render skeleton for a lazy-loaded Turbo Frame
  #
  # This is useful for showing skeleton content while waiting for
  # a lazy-loaded Turbo Frame to complete loading.
  #
  # @param frame_id [String] The Turbo Frame ID
  # @param src [String] The source URL for lazy loading
  # @param variant [Symbol] The skeleton variant to show while loading
  # @param options [Hash] Additional options
  # @return [String] Rendered Turbo Frame with skeleton HTML
  def skeleton_turbo_frame(frame_id:, src:, variant: :card, **options)
    turbo_frame_tag(frame_id, src: src, loading: "lazy") do
      skeleton(variant, **options)
    end
  end

  # Render skeleton for dashboard sections
  #
  # @param variant [Symbol] Dashboard section type (:projects, :agreements, :meetings, :stats)
  # @param count [Integer] Number of items to show
  # @return [String] Rendered dashboard skeleton HTML
  def skeleton_dashboard_section(variant, count: 3)
    case variant
    when :projects
      skeleton_container(title: "Recent Projects") do
        skeleton_list(:list_item, count: count)
      end
    when :agreements
      skeleton_container(title: "Active Agreements") do
        skeleton_list(:list_item, count: count)
      end
    when :meetings
      skeleton_container(title: "Upcoming Meetings") do
        safe_join(count.times.map { skeleton(:meeting_item) })
      end
    when :stats
      skeleton(:stats, count: count)
    else
      skeleton(:dashboard_widget)
    end
  end

  # Render inline skeleton text (useful for loading states within text)
  #
  # @param width [Symbol, String] Width of the skeleton
  # @param height [Symbol] Height variant (:sm, :md, :lg)
  # @return [String] Rendered inline skeleton HTML
  def skeleton_inline(width: :quarter, height: :md)
    height_class = case height
    when :xs then "h-3"
    when :sm then "h-4"
    when :md then "h-5"
    when :lg then "h-6"
    else "h-4"
    end

    width_class = case width
    when :full then "w-full"
    when :half then "w-1/2"
    when :third then "w-1/3"
    when :quarter then "w-1/4"
    when :three_quarters then "w-3/4"
    else width.to_s
    end

    content_tag(:span, nil, class: "skeleton inline-block #{height_class} #{width_class} align-middle rounded")
  end

  # Render skeleton for profile/user information
  #
  # @param variant [Symbol] Profile layout (:full, :compact, :header)
  # @return [String] Rendered profile skeleton HTML
  def skeleton_profile(variant = :full)
    case variant
    when :header
      content_tag(:div, class: "flex items-center gap-4") do
        safe_join([
          skeleton(:avatar_lg),
          content_tag(:div, class: "flex-1") do
            safe_join([
              skeleton(:title, width: :half),
              skeleton(:text_sm, width: :third, css_class: "mt-2")
            ])
          end
        ])
      end
    when :compact
      content_tag(:div, class: "flex items-center gap-3") do
        safe_join([
          skeleton(:avatar_sm),
          skeleton(:text, width: :half)
        ])
      end
    else
      skeleton(:user_card)
    end
  end

  private

  def render_skeleton_placeholder(variant, count, layout, options)
    content_tag(:div, data: { skeleton_loader_target: "skeleton" }) do
      case layout
      when :grid
        render Skeletons::GridComponent.new(variant: variant, count: count, **options)
      when :list
        render Skeletons::ListComponent.new(count: count, **options)
      when :table
        render Skeletons::TableComponent.new(rows: count, **options)
      else
        if count > 1
          safe_join(count.times.map { render Ui::SkeletonComponent.new(variant: variant, **options) })
        else
          render Ui::SkeletonComponent.new(variant: variant, **options)
        end
      end
    end
  end
end
