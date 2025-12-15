# frozen_string_literal: true

module Ui
  # DaisyUI Skeleton Component for loading placeholders
  #
  # A comprehensive skeleton loading system that provides visual feedback
  # during content loading. Supports multiple variants from simple text
  # to complex card layouts.
  #
  # Usage Examples:
  #   # Simple variants
  #   <%= render Ui::SkeletonComponent.new(variant: :text) %>
  #   <%= render Ui::SkeletonComponent.new(variant: :title, width: :three_quarters) %>
  #   <%= render Ui::SkeletonComponent.new(variant: :avatar, size: :lg) %>
  #
  #   # Multiple items with count
  #   <%= render Ui::SkeletonComponent.new(variant: :text, count: 3) %>
  #
  #   # Complex variants
  #   <%= render Ui::SkeletonComponent.new(variant: :project_card) %>
  #   <%= render Ui::SkeletonComponent.new(variant: :user_card) %>
  #   <%= render Ui::SkeletonComponent.new(variant: :agreement_row) %>
  #
  #   # With animation variants
  #   <%= render Ui::SkeletonComponent.new(variant: :card, animate: :pulse) %>
  #   <%= render Ui::SkeletonComponent.new(variant: :card, animate: :wave) %>
  #
  class SkeletonComponent < ApplicationComponent
    # Base element variants with their default classes
    VARIANTS = {
      # Text variants
      text: "skeleton h-4 w-full",
      text_sm: "skeleton h-3 w-full",
      text_lg: "skeleton h-5 w-full",
      title: "skeleton h-8 w-3/4",
      subtitle: "skeleton h-6 w-1/2",
      heading: "skeleton h-10 w-2/3",

      # Avatar variants
      avatar: "skeleton h-12 w-12 rounded-full shrink-0",
      avatar_xs: "skeleton h-6 w-6 rounded-full shrink-0",
      avatar_sm: "skeleton h-8 w-8 rounded-full shrink-0",
      avatar_md: "skeleton h-12 w-12 rounded-full shrink-0",
      avatar_lg: "skeleton h-16 w-16 rounded-full shrink-0",
      avatar_xl: "skeleton h-24 w-24 rounded-full shrink-0",

      # Image variants
      image: "skeleton h-32 w-full rounded-lg",
      image_sm: "skeleton h-24 w-full rounded-lg",
      image_lg: "skeleton h-48 w-full rounded-lg",
      image_xl: "skeleton h-64 w-full rounded-lg",
      thumbnail: "skeleton h-20 w-20 rounded-lg shrink-0",

      # UI element variants
      badge: "skeleton h-5 w-16 rounded-full",
      badge_lg: "skeleton h-6 w-20 rounded-full",
      button: "skeleton h-10 w-24 rounded-lg",
      button_sm: "skeleton h-8 w-20 rounded-lg",
      button_lg: "skeleton h-12 w-32 rounded-lg",
      input: "skeleton h-10 w-full rounded-lg",
      checkbox: "skeleton h-5 w-5 rounded",
      icon: "skeleton h-5 w-5 rounded",
      icon_lg: "skeleton h-8 w-8 rounded",

      # Layout variants
      divider: "skeleton h-px w-full",
      spacer: "skeleton h-4 w-4"
    }.freeze

    # Width modifiers
    WIDTH_CLASSES = {
      full: "w-full",
      half: "w-1/2",
      third: "w-1/3",
      quarter: "w-1/4",
      three_quarters: "w-3/4",
      two_thirds: "w-2/3"
    }.freeze

    # Animation variants
    ANIMATIONS = {
      default: "", # DaisyUI skeleton has built-in animation
      pulse: "animate-pulse",
      wave: "animate-shimmer",
      none: "!animate-none"
    }.freeze

    # @param variant [Symbol] The skeleton variant type
    # @param count [Integer] Number of skeleton elements to render
    # @param css_class [String] Additional CSS classes
    # @param width [Symbol, String] Width modifier (:full, :half, :third, :quarter, :three_quarters, :two_thirds or custom class)
    # @param animate [Symbol] Animation type (:default, :pulse, :wave, :none)
    # @param gap [Symbol] Gap between multiple elements (:sm, :md, :lg)
    # @param stagger [Boolean] Apply staggered animation delays to multiple elements
    def initialize(
      variant: :text,
      count: 1,
      css_class: nil,
      width: nil,
      animate: :default,
      gap: :md,
      stagger: false
    )
      @variant = variant
      @count = count
      @css_class = css_class
      @width = width
      @animate = animate
      @gap = gap
      @stagger = stagger
    end

    def call
      case @variant
      when :paragraph then render_paragraph
      when :card then render_card
      when :card_compact then render_card_compact
      when :user_card then render_user_card
      when :project_card then render_project_card
      when :project_card_compact then render_project_card_compact
      when :agreement_card then render_agreement_card
      when :agreement_row then render_agreement_row
      when :table_row then render_table_row
      when :list_item then render_list_item
      when :list_item_compact then render_list_item_compact
      when :stats then render_stats
      when :stats_single then render_stats_single
      when :form then render_form
      when :form_field then render_form_field
      when :conversation_item then render_conversation_item
      when :meeting_item then render_meeting_item
      when :milestone_item then render_milestone_item
      when :notification then render_notification
      when :navbar then render_navbar
      when :page_header then render_page_header
      when :dashboard_widget then render_dashboard_widget
      else render_simple
      end
    end

    private

    def gap_class
      case @gap
      when :xs then "gap-1"
      when :sm then "gap-2"
      when :md then "gap-3"
      when :lg then "gap-4"
      when :xl then "gap-6"
      else "gap-3"
      end
    end

    def animation_class
      ANIMATIONS[@animate] || ""
    end

    def stagger_delay(index)
      return "" unless @stagger

      delays = %w[delay-0 delay-75 delay-100 delay-150 delay-200]
      delays[index % delays.length]
    end

    def render_simple
      if @count > 1
        tag.div(class: "flex flex-col #{gap_class} #{@css_class}") do
          safe_join(@count.times.map { |i| skeleton_element(stagger_index: i) })
        end
      else
        skeleton_element
      end
    end

    def skeleton_element(stagger_index: 0)
      classes = VARIANTS[@variant] || VARIANTS[:text]
      classes = "#{classes} #{width_class}" if @width.present?
      classes = "#{classes} #{animation_class}" if @animate != :default
      classes = "#{classes} #{stagger_delay(stagger_index)}" if @stagger
      classes = "#{classes} #{@css_class}" if @css_class.present? && @count == 1
      tag.div(class: classes)
    end

    def width_class
      WIDTH_CLASSES[@width] || (@width.is_a?(String) ? @width : nil)
    end

    # Paragraph: 3 lines with varying widths
    def render_paragraph
      tag.div(class: "flex flex-col #{gap_class} #{@css_class}") do
        safe_join([
          tag.div(class: "skeleton h-4 w-full #{animation_class}"),
          tag.div(class: "skeleton h-4 w-full #{animation_class}"),
          tag.div(class: "skeleton h-4 w-3/4 #{animation_class}")
        ])
      end
    end

    # Generic card skeleton
    def render_card
      tag.div(class: "card bg-base-100 shadow-xl #{@css_class}", role: "status", "aria-label": "Loading") do
        tag.div(class: "card-body") do
          safe_join([
            tag.div(class: "skeleton h-8 w-3/4 mb-4 #{animation_class}"),
            tag.div(class: "skeleton h-4 w-full mb-2 #{animation_class}"),
            tag.div(class: "skeleton h-4 w-full mb-2 #{animation_class}"),
            tag.div(class: "skeleton h-4 w-1/2 #{animation_class}")
          ])
        end
      end
    end

    # Compact card skeleton
    def render_card_compact
      tag.div(class: "card card-compact bg-base-100 shadow-lg #{@css_class}", role: "status", "aria-label": "Loading") do
        tag.div(class: "card-body") do
          safe_join([
            tag.div(class: "skeleton h-6 w-2/3 mb-3 #{animation_class}"),
            tag.div(class: "skeleton h-3 w-full mb-1 #{animation_class}"),
            tag.div(class: "skeleton h-3 w-3/4 #{animation_class}")
          ])
        end
      end
    end

    # User card with avatar, name, bio
    def render_user_card
      tag.div(class: "card bg-base-100 shadow-xl #{@css_class}", role: "status", "aria-label": "Loading user") do
        tag.div(class: "card-body items-center text-center") do
          safe_join([
            # Avatar
            tag.div(class: "skeleton h-24 w-24 rounded-full mb-4 #{animation_class}"),
            # Name
            tag.div(class: "skeleton h-6 w-32 mb-2 #{animation_class}"),
            # Title/Role
            tag.div(class: "skeleton h-4 w-24 mb-4 #{animation_class}"),
            # Skills/badges
            tag.div(class: "flex gap-2 justify-center") do
              safe_join([
                tag.div(class: "skeleton h-5 w-16 rounded-full #{animation_class}"),
                tag.div(class: "skeleton h-5 w-16 rounded-full #{animation_class}"),
                tag.div(class: "skeleton h-5 w-16 rounded-full #{animation_class}")
              ])
            end,
            # Stats
            tag.div(class: "flex gap-6 mt-4") do
              safe_join([
                tag.div(class: "flex flex-col items-center") do
                  safe_join([
                    tag.div(class: "skeleton h-6 w-8 mb-1 #{animation_class}"),
                    tag.div(class: "skeleton h-3 w-12 #{animation_class}")
                  ])
                end,
                tag.div(class: "flex flex-col items-center") do
                  safe_join([
                    tag.div(class: "skeleton h-6 w-8 mb-1 #{animation_class}"),
                    tag.div(class: "skeleton h-3 w-12 #{animation_class}")
                  ])
                end
              ])
            end
          ])
        end
      end
    end

    # Project card matching the actual project card layout
    def render_project_card
      tag.article(class: "card bg-base-100 shadow-xl #{@css_class}", role: "status", "aria-label": "Loading project") do
        safe_join([
          # Status bar
          tag.div(class: "h-1 bg-base-300 rounded-t-2xl"),
          tag.div(class: "card-body p-6") do
            safe_join([
              # Icon and title section
              tag.div(class: "flex items-start gap-4 mb-4") do
                safe_join([
                  # Project icon
                  tag.div(class: "skeleton h-14 w-14 rounded-xl shrink-0 #{animation_class}"),
                  tag.div(class: "flex-1 min-w-0") do
                    safe_join([
                      # Title
                      tag.div(class: "skeleton h-6 w-3/4 mb-2 #{animation_class}"),
                      # Badges
                      tag.div(class: "flex gap-2") do
                        safe_join([
                          tag.div(class: "skeleton h-5 w-16 rounded-full #{animation_class}"),
                          tag.div(class: "skeleton h-5 w-14 rounded-full #{animation_class}")
                        ])
                      end,
                      # Time
                      tag.div(class: "skeleton h-3 w-32 mt-2 #{animation_class}")
                    ])
                  end
                ])
              end,
              # Description
              tag.div(class: "skeleton h-4 w-full mb-2 #{animation_class}"),
              tag.div(class: "skeleton h-4 w-2/3 mb-4 #{animation_class}"),
              # Stats
              tag.div(class: "stats stats-horizontal bg-base-200 shadow-sm w-full") do
                safe_join([
                  tag.div(class: "stat py-2 px-3") do
                    safe_join([
                      tag.div(class: "stat-title") { tag.div(class: "skeleton h-3 w-16 #{animation_class}") },
                      tag.div(class: "stat-value") { tag.div(class: "skeleton h-5 w-8 mt-1 #{animation_class}") }
                    ])
                  end,
                  tag.div(class: "stat py-2 px-3") do
                    safe_join([
                      tag.div(class: "stat-title") { tag.div(class: "skeleton h-3 w-16 #{animation_class}") },
                      tag.div(class: "stat-value") { tag.div(class: "skeleton h-5 w-8 mt-1 #{animation_class}") }
                    ])
                  end
                ])
              end
            ])
          end,
          # Card actions
          tag.div(class: "card-actions justify-between items-center p-4 pt-0") do
            safe_join([
              tag.div(class: "skeleton h-8 w-20 rounded-lg #{animation_class}"),
              tag.div(class: "flex items-center gap-2") do
                safe_join([
                  tag.div(class: "skeleton h-8 w-16 rounded-lg #{animation_class}"),
                  tag.div(class: "skeleton h-8 w-8 rounded-lg #{animation_class}")
                ])
              end
            ])
          end
        ])
      end
    end

    # Compact project card for grids
    def render_project_card_compact
      tag.div(class: "card card-compact bg-base-200 #{@css_class}", role: "status", "aria-label": "Loading project") do
        tag.div(class: "card-body") do
          safe_join([
            # Header
            tag.div(class: "flex items-start justify-between gap-2") do
              safe_join([
                tag.div(class: "skeleton h-5 w-2/3 #{animation_class}"),
                tag.div(class: "skeleton h-5 w-12 rounded-full #{animation_class}")
              ])
            end,
            # Description
            tag.div(class: "min-h-[2.5rem] mt-2") do
              safe_join([
                tag.div(class: "skeleton h-3 w-full mb-1 #{animation_class}"),
                tag.div(class: "skeleton h-3 w-3/4 #{animation_class}")
              ])
            end,
            # Footer
            tag.div(class: "flex justify-between items-center mt-3 pt-2 border-t border-base-300") do
              safe_join([
                tag.div(class: "flex items-center gap-2") do
                  safe_join([
                    tag.div(class: "skeleton h-6 w-6 rounded-full #{animation_class}"),
                    tag.div(class: "skeleton h-3 w-20 #{animation_class}")
                  ])
                end,
                tag.div(class: "skeleton h-6 w-12 rounded-lg #{animation_class}")
              ])
            end
          ])
        end
      end
    end

    # Agreement card skeleton
    def render_agreement_card
      tag.div(class: "card bg-base-100 shadow-xl #{@css_class}", role: "status", "aria-label": "Loading agreement") do
        tag.div(class: "card-body") do
          safe_join([
            # Header with status
            tag.div(class: "flex items-start justify-between mb-4") do
              safe_join([
                tag.div(class: "flex items-center gap-3") do
                  safe_join([
                    tag.div(class: "skeleton h-10 w-10 rounded-full #{animation_class}"),
                    tag.div do
                      safe_join([
                        tag.div(class: "skeleton h-5 w-32 mb-1 #{animation_class}"),
                        tag.div(class: "skeleton h-3 w-24 #{animation_class}")
                      ])
                    end
                  ])
                end,
                tag.div(class: "skeleton h-6 w-20 rounded-full #{animation_class}")
              ])
            end,
            # Description
            tag.div(class: "skeleton h-4 w-full mb-2 #{animation_class}"),
            tag.div(class: "skeleton h-4 w-3/4 mb-4 #{animation_class}"),
            # Stats
            tag.div(class: "flex gap-4") do
              safe_join([
                tag.div(class: "skeleton h-4 w-20 #{animation_class}"),
                tag.div(class: "skeleton h-4 w-24 #{animation_class}")
              ])
            end
          ])
        end
      end
    end

    # Agreement table row skeleton
    def render_agreement_row
      tag.tr(class: @css_class, role: "status", "aria-label": "Loading") do
        safe_join([
          tag.td(class: "py-4") do
            tag.div(class: "flex items-center gap-3") do
              safe_join([
                tag.div(class: "skeleton h-10 w-10 rounded-full #{animation_class}"),
                tag.div do
                  safe_join([
                    tag.div(class: "skeleton h-4 w-28 mb-1 #{animation_class}"),
                    tag.div(class: "skeleton h-3 w-20 #{animation_class}")
                  ])
                end
              ])
            end
          end,
          tag.td { tag.div(class: "skeleton h-4 w-32 #{animation_class}") },
          tag.td { tag.div(class: "skeleton h-5 w-16 rounded-full #{animation_class}") },
          tag.td { tag.div(class: "skeleton h-4 w-20 #{animation_class}") },
          tag.td { tag.div(class: "skeleton h-8 w-20 rounded-lg #{animation_class}") }
        ])
      end
    end

    # Generic table row
    def render_table_row
      cells = @count > 1 ? @count : 5
      tag.tr(class: @css_class, role: "status", "aria-label": "Loading") do
        safe_join(cells.times.map do |i|
          widths = %w[w-24 w-32 w-20 w-16 w-28]
          tag.td { tag.div(class: "skeleton h-4 #{widths[i % widths.length]} #{animation_class}") }
        end)
      end
    end

    # List item with avatar
    def render_list_item
      tag.li(class: "flex items-center gap-4 p-4 #{@css_class}", role: "status", "aria-label": "Loading") do
        safe_join([
          tag.div(class: "skeleton h-12 w-12 rounded-full shrink-0 #{animation_class}"),
          tag.div(class: "flex-1 flex flex-col gap-2") do
            safe_join([
              tag.div(class: "skeleton h-4 w-3/4 #{animation_class}"),
              tag.div(class: "skeleton h-3 w-1/2 #{animation_class}")
            ])
          end,
          tag.div(class: "skeleton h-8 w-16 rounded-lg shrink-0 #{animation_class}")
        ])
      end
    end

    # Compact list item
    def render_list_item_compact
      tag.li(class: "flex items-center gap-3 p-2 #{@css_class}", role: "status", "aria-label": "Loading") do
        safe_join([
          tag.div(class: "skeleton h-8 w-8 rounded-full shrink-0 #{animation_class}"),
          tag.div(class: "flex-1") do
            tag.div(class: "skeleton h-4 w-2/3 #{animation_class}")
          end
        ])
      end
    end

    # Stats widget with 3 stats
    def render_stats
      stat_count = @count > 1 ? @count : 3
      tag.div(class: "stats shadow bg-base-100 w-full #{@css_class}", role: "status", "aria-label": "Loading statistics") do
        safe_join(stat_count.times.map do
          tag.div(class: "stat") do
            safe_join([
              tag.div(class: "stat-title") { tag.div(class: "skeleton h-3 w-16 #{animation_class}") },
              tag.div(class: "stat-value") { tag.div(class: "skeleton h-8 w-20 mt-2 #{animation_class}") },
              tag.div(class: "stat-desc") { tag.div(class: "skeleton h-3 w-24 mt-2 #{animation_class}") }
            ])
          end
        end)
      end
    end

    # Single stat
    def render_stats_single
      tag.div(class: "stat #{@css_class}", role: "status", "aria-label": "Loading statistic") do
        safe_join([
          tag.div(class: "stat-figure text-primary") { tag.div(class: "skeleton h-8 w-8 rounded #{animation_class}") },
          tag.div(class: "stat-title") { tag.div(class: "skeleton h-3 w-16 #{animation_class}") },
          tag.div(class: "stat-value") { tag.div(class: "skeleton h-8 w-20 mt-1 #{animation_class}") },
          tag.div(class: "stat-desc") { tag.div(class: "skeleton h-3 w-24 mt-1 #{animation_class}") }
        ])
      end
    end

    # Form skeleton
    def render_form
      field_count = @count > 1 ? @count : 4
      tag.div(class: "space-y-4 #{@css_class}", role: "status", "aria-label": "Loading form") do
        safe_join([
          # Form fields
          safe_join(field_count.times.map { render_form_field_content }),
          # Submit button
          tag.div(class: "pt-4") do
            tag.div(class: "skeleton h-10 w-32 rounded-lg #{animation_class}")
          end
        ])
      end
    end

    # Single form field
    def render_form_field
      tag.div(class: @css_class) do
        render_form_field_content
      end
    end

    def render_form_field_content
      tag.div(class: "form-control") do
        safe_join([
          tag.label(class: "label") { tag.div(class: "skeleton h-4 w-24 #{animation_class}") },
          tag.div(class: "skeleton h-10 w-full rounded-lg #{animation_class}")
        ])
      end
    end

    # Conversation item skeleton
    def render_conversation_item
      tag.div(class: "flex gap-3 p-4 #{@css_class}", role: "status", "aria-label": "Loading conversation") do
        safe_join([
          tag.div(class: "skeleton h-10 w-10 rounded-full shrink-0 #{animation_class}"),
          tag.div(class: "flex-1") do
            safe_join([
              tag.div(class: "flex justify-between items-start mb-2") do
                safe_join([
                  tag.div(class: "skeleton h-4 w-24 #{animation_class}"),
                  tag.div(class: "skeleton h-3 w-16 #{animation_class}")
                ])
              end,
              tag.div(class: "skeleton h-4 w-full mb-1 #{animation_class}"),
              tag.div(class: "skeleton h-4 w-2/3 #{animation_class}")
            ])
          end
        ])
      end
    end

    # Meeting item skeleton
    def render_meeting_item
      tag.div(class: "flex items-center gap-4 p-4 border-b border-base-200 #{@css_class}", role: "status", "aria-label": "Loading meeting") do
        safe_join([
          # Date box
          tag.div(class: "skeleton h-16 w-16 rounded-lg shrink-0 #{animation_class}"),
          tag.div(class: "flex-1") do
            safe_join([
              tag.div(class: "skeleton h-5 w-48 mb-2 #{animation_class}"),
              tag.div(class: "skeleton h-4 w-32 #{animation_class}")
            ])
          end,
          tag.div(class: "skeleton h-8 w-20 rounded-lg shrink-0 #{animation_class}")
        ])
      end
    end

    # Milestone item skeleton
    def render_milestone_item
      tag.div(class: "flex items-start gap-3 p-4 #{@css_class}", role: "status", "aria-label": "Loading milestone") do
        safe_join([
          tag.div(class: "skeleton h-5 w-5 rounded shrink-0 mt-0.5 #{animation_class}"),
          tag.div(class: "flex-1") do
            safe_join([
              tag.div(class: "skeleton h-5 w-3/4 mb-2 #{animation_class}"),
              tag.div(class: "skeleton h-4 w-full mb-1 #{animation_class}"),
              tag.div(class: "skeleton h-4 w-1/2 mb-2 #{animation_class}"),
              tag.div(class: "flex gap-2") do
                safe_join([
                  tag.div(class: "skeleton h-4 w-16 rounded-full #{animation_class}"),
                  tag.div(class: "skeleton h-4 w-20 #{animation_class}")
                ])
              end
            ])
          end
        ])
      end
    end

    # Notification skeleton
    def render_notification
      tag.div(class: "flex items-start gap-3 p-3 #{@css_class}", role: "status", "aria-label": "Loading notification") do
        safe_join([
          tag.div(class: "skeleton h-8 w-8 rounded-full shrink-0 #{animation_class}"),
          tag.div(class: "flex-1") do
            safe_join([
              tag.div(class: "skeleton h-4 w-full mb-1 #{animation_class}"),
              tag.div(class: "skeleton h-3 w-24 #{animation_class}")
            ])
          end
        ])
      end
    end

    # Navbar skeleton
    def render_navbar
      tag.div(class: "navbar bg-base-100 shadow-lg #{@css_class}", role: "status", "aria-label": "Loading navigation") do
        safe_join([
          tag.div(class: "flex-1") do
            tag.div(class: "skeleton h-8 w-32 #{animation_class}")
          end,
          tag.div(class: "flex-none gap-2") do
            safe_join([
              tag.div(class: "skeleton h-8 w-20 rounded-lg #{animation_class}"),
              tag.div(class: "skeleton h-8 w-20 rounded-lg #{animation_class}"),
              tag.div(class: "skeleton h-10 w-10 rounded-full #{animation_class}")
            ])
          end
        ])
      end
    end

    # Page header skeleton
    def render_page_header
      tag.div(class: "card bg-base-100 shadow-xl #{@css_class}", role: "status", "aria-label": "Loading page header") do
        tag.div(class: "card-body") do
          tag.div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4") do
            safe_join([
              tag.div do
                safe_join([
                  tag.div(class: "skeleton h-8 w-48 mb-2 #{animation_class}"),
                  tag.div(class: "skeleton h-4 w-64 #{animation_class}")
                ])
              end,
              tag.div(class: "skeleton h-10 w-32 rounded-lg #{animation_class}")
            ])
          end
        end
      end
    end

    # Dashboard widget skeleton
    def render_dashboard_widget
      tag.div(class: "card bg-base-100 shadow-xl #{@css_class}", role: "status", "aria-label": "Loading widget") do
        tag.div(class: "card-body") do
          safe_join([
            # Header
            tag.div(class: "flex justify-between items-center mb-4") do
              safe_join([
                tag.div(class: "skeleton h-6 w-40 #{animation_class}"),
                tag.div(class: "skeleton h-6 w-16 rounded-lg #{animation_class}")
              ])
            end,
            # Content items
            safe_join(3.times.map do
              tag.div(class: "flex items-center gap-3 py-2") do
                safe_join([
                  tag.div(class: "skeleton h-10 w-10 rounded-lg shrink-0 #{animation_class}"),
                  tag.div(class: "flex-1") do
                    safe_join([
                      tag.div(class: "skeleton h-4 w-3/4 mb-1 #{animation_class}"),
                      tag.div(class: "skeleton h-3 w-1/2 #{animation_class}")
                    ])
                  end
                ])
              end
            end)
          ])
        end
      end
    end
  end
end
