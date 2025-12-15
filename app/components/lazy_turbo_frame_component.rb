# frozen_string_literal: true

# Lazy-loaded Turbo Frame component with skeleton or spinner placeholder
#
# @example Basic usage with spinner placeholder
#   <%= render LazyTurboFrameComponent.new(
#     frame_id: "github_section",
#     src_path: github_section_path,
#     title: "GitHub Integration",
#     description: "Loading repository data..."
#   ) %>
#
# @example With skeleton placeholder
#   <%= render LazyTurboFrameComponent.new(
#     frame_id: "projects_list",
#     src_path: projects_path,
#     skeleton_variant: :list_item,
#     skeleton_count: 5
#   ) %>
#
# @example With grid skeleton
#   <%= render LazyTurboFrameComponent.new(
#     frame_id: "project_cards",
#     src_path: projects_path,
#     placeholder: :skeleton,
#     skeleton_variant: :project_card,
#     skeleton_count: 6,
#     skeleton_layout: :grid
#   ) %>
#
class LazyTurboFrameComponent < ApplicationComponent
  # @param frame_id [String] The Turbo Frame ID
  # @param src_path [String] The URL to load content from
  # @param title [String, nil] Title for spinner placeholder
  # @param description [String, nil] Description for spinner placeholder
  # @param placeholder [Symbol] Placeholder type (:spinner or :skeleton)
  # @param skeleton_variant [Symbol] Skeleton variant when using skeleton placeholder
  # @param skeleton_count [Integer] Number of skeleton items
  # @param skeleton_layout [Symbol] Layout type for skeletons (:single, :grid, :list, :table)
  # @param css_class [String] Additional CSS classes for the frame
  def initialize(
    frame_id:,
    src_path:,
    title: nil,
    description: nil,
    placeholder: :spinner,
    skeleton_variant: :card,
    skeleton_count: 1,
    skeleton_layout: :single,
    css_class: nil
  )
    @frame_id = frame_id
    @src_path = src_path
    @title = title
    @description = description
    @placeholder = placeholder
    @skeleton_variant = skeleton_variant
    @skeleton_count = skeleton_count
    @skeleton_layout = skeleton_layout
    @css_class = css_class
  end

  def call
    helpers.turbo_frame_tag(@frame_id, src: @src_path, loading: "lazy", class: @css_class) do
      render_placeholder
    end
  end

  private

  def render_placeholder
    if use_skeleton?
      render_skeleton_placeholder
    else
      render_spinner_placeholder
    end
  end

  def use_skeleton?
    @placeholder == :skeleton || @skeleton_variant.present? && @title.blank?
  end

  def render_skeleton_placeholder
    case @skeleton_layout
    when :grid
      render(Skeletons::GridComponent.new(
        variant: @skeleton_variant,
        count: @skeleton_count
      ))
    when :list
      render(Skeletons::ListComponent.new(count: @skeleton_count))
    when :table
      render(Skeletons::TableComponent.new(rows: @skeleton_count))
    else
      if @skeleton_count > 1
        tag.div(class: "space-y-4") do
          safe_join(@skeleton_count.times.map do
            render(Ui::SkeletonComponent.new(variant: @skeleton_variant))
          end)
        end
      else
        render(Ui::SkeletonComponent.new(variant: @skeleton_variant))
      end
    end
  end

  def render_spinner_placeholder
    render(Ui::LoadingPlaceholderComponent.new(
      title: @title,
      description: @description
    ))
  end
end
