# frozen_string_literal: true

module Skeletons
  # Table skeleton component for displaying loading state in data tables
  #
  # @example Basic usage
  #   <%= render Skeletons::TableComponent.new(rows: 5, columns: 4) %>
  #
  # @example With custom column widths
  #   <%= render Skeletons::TableComponent.new(
  #     rows: 10,
  #     columns: 4,
  #     column_widths: %w[w-32 w-48 w-24 w-20],
  #     with_header: true
  #   ) %>
  #
  class TableComponent < ApplicationComponent
    DEFAULT_WIDTHS = %w[w-24 w-32 w-20 w-16 w-28].freeze

    # @param rows [Integer] Number of skeleton rows
    # @param columns [Integer] Number of columns per row
    # @param column_widths [Array<String>] CSS width classes for each column
    # @param with_header [Boolean] Include header row
    # @param css_class [String] Additional CSS classes
    # @param label [String] Accessible label
    def initialize(
      rows: 5,
      columns: 5,
      column_widths: nil,
      with_header: true,
      css_class: nil,
      label: "Loading table"
    )
      @rows = rows
      @columns = columns
      @column_widths = column_widths || DEFAULT_WIDTHS
      @with_header = with_header
      @css_class = css_class
      @label = label
    end

    def call
      tag.div(
        class: class_names("overflow-x-auto", @css_class),
        role: "status",
        "aria-label": @label
      ) do
        safe_join([
          render_table,
          tag.span("#{@label}...", class: "sr-only")
        ])
      end
    end

    private

    def render_table
      tag.table(class: "table") do
        safe_join([
          render_header,
          render_body
        ].compact)
      end
    end

    def render_header
      return nil unless @with_header

      tag.thead do
        tag.tr do
          safe_join(@columns.times.map do |i|
            tag.th { tag.div(class: "skeleton h-4 #{width_for(i)}") }
          end)
        end
      end
    end

    def render_body
      tag.tbody do
        safe_join(@rows.times.map { render_row })
      end
    end

    def render_row
      tag.tr do
        safe_join(@columns.times.map do |i|
          tag.td { tag.div(class: "skeleton h-4 #{width_for(i)}") }
        end)
      end
    end

    def width_for(index)
      @column_widths[index % @column_widths.length]
    end
  end
end
