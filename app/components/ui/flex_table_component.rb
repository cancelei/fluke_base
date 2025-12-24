# frozen_string_literal: true

module Ui
  # Flexible div-based table component using CSS Grid 12-column system
  #
  # Replaces HTML tables with responsive div layouts that support configurable column spans
  #
  # @example Basic usage (Projects table)
  #   <%= render Ui::FlexTableComponent.new(
  #     columns: [
  #       { span: 2, header: "Project" },
  #       { span: 2, header: "Stage" },
  #       { span: 2, header: "Milestones", responsive: "hidden md:flex" },
  #       { span: 1, header: "Agreements", responsive: "hidden md:flex" },
  #       { span: 1, header: "Team", responsive: "hidden lg:flex" },
  #       { span: 2, header: "Updated", responsive: "hidden sm:flex" },
  #       { span: 2, header: "Actions", align: "right" }
  #     ],
  #     rows: [
  #       ["Project Alpha", "Active", "5 milestones", "2", "Team", "2h ago", link_to("View", "#")],
  #       ["Project Beta", "Planning", "2 milestones", "1", "-", "1d ago", link_to("View", "#")]
  #     ]
  #   ) %>
  #
  # @example With fixed-width columns
  #   <%= render Ui::FlexTableComponent.new(
  #     columns: [
  #       { span: 3, header: "Name" },
  #       { span: 2, header: "Status", fixed: true, width: "w-24" },
  #       { span: 4, header: "Description" },
  #       { span: 3, header: "Actions" }
  #     ],
  #     rows: [["Item 1", "Active", "Description here", "Edit"]]
  #   ) %>
  #
  class FlexTableComponent < ApplicationComponent
    # @param columns [Array<Hash>] Column configuration
    #   - span: [Integer] Number of grid columns (1-12)
    #   - header: [String] Column header text
    #   - fixed: [Boolean] Whether column has fixed width (won't shrink)
    #   - width: [String] Tailwind width class (e.g., "w-32", "w-48")
    #   - responsive: [String] Tailwind responsive classes (e.g., "hidden md:flex")
    #   - align: [String] Text alignment ("left", "center", "right")
    # @param rows [Array<Array>] Array of row data, each row is an array of cell content
    # @param css_class [String] Additional CSS classes for the table container
    # @param zebra [Boolean] Alternate row colors
    # @param hover [Boolean] Add hover effect to rows
    def initialize(
      columns: [],
      rows: [],
      css_class: nil,
      zebra: false,
      hover: true
    )
      @columns = columns
      @rows = rows
      @css_class = css_class
      @zebra = zebra
      @hover = hover

      validate_columns!
    end

    def call
      tag.div(
        class: class_names(
          "flex-table grid gap-0 border border-base-300 rounded-lg overflow-hidden bg-base-100",
          @css_class
        ),
        style: grid_style
      ) do
        safe_join([
          render_header,
          render_rows
        ])
      end
    end

    private

    def validate_columns!
      # Note: We don't enforce total span = 12 because columns may be hidden responsively
      # CSS Grid will handle the layout automatically
    end

    def grid_style
      # Create CSS Grid template columns based on spans
      template = @columns.map do |col|
        if col[:fixed] && col[:width]
          # Convert Tailwind width classes to approximate rem values
          width_rem = case col[:width]
          when "w-16" then "4rem"
          when "w-20" then "5rem"
          when "w-24" then "6rem"
          when "w-32" then "8rem"
          when "w-48" then "12rem"
          else "auto"
          end
          "minmax(#{width_rem}, #{width_rem})"
        else
          "#{col[:span]}fr"
        end
      end.join(" ")

      "grid-template-columns: #{template};"
    end

    def render_header
      return nil if @columns.none? { |col| col[:header] }

      tag.div(class: "flex-table-header contents bg-base-200 border-b border-base-300") do
        safe_join(@columns.map do |column|
          next nil unless column[:header]

          cell_classes = class_names(
            "flex-table-cell p-3 font-semibold text-base-content flex items-center",
            column[:responsive],
            "justify-#{column[:align] || 'start'}"
          )

          tag.div(class: cell_classes) { column[:header] }
        end.compact)
      end
    end

    def render_rows
      return nil if @rows.empty?

      safe_join(@rows.each_with_index.map do |row_data, row_index|
        row_classes = class_names(
          "flex-table-row contents border-b border-base-300 last:border-b-0",
          @hover ? "hover:bg-base-200" : nil,
          @zebra && row_index.even? ? "bg-base-200/50" : nil
        )

        tag.div(class: row_classes) do
          safe_join(row_data.each_with_index.map do |cell_content, cell_index|
            column = @columns[cell_index] || {}
            cell_classes = class_names(
              "flex-table-cell p-3 flex items-center",
              column[:responsive],
              "justify-#{column[:align] || 'start'}",
              column[:fixed] ? "flex-none" : "min-w-0"
            )

            tag.div(class: cell_classes) { cell_content.html_safe }
          end)
        end
      end)
    end
  end
end
