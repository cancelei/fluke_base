# frozen_string_literal: true

module Skeletons
  # Form skeleton component for displaying loading state in forms
  #
  # @example Basic usage
  #   <%= render Skeletons::FormComponent.new(fields: 4) %>
  #
  # @example Without submit buttons
  #   <%= render Skeletons::FormComponent.new(fields: 3, with_actions: false) %>
  #
  class FormComponent < ApplicationComponent
    FIELD_TYPES = {
      input: { height: "h-10" },
      textarea: { height: "h-24" },
      select: { height: "h-10" },
      checkbox: { height: "h-5", width: "w-5" }
    }.freeze

    # @param fields [Integer, Array<Symbol>] Number of fields or array of field types
    # @param with_actions [Boolean] Show form action buttons
    # @param with_cancel [Boolean] Show cancel button (when with_actions is true)
    # @param css_class [String] Additional CSS classes
    # @param label [String] Accessible label
    def initialize(
      fields: 4,
      with_actions: true,
      with_cancel: true,
      css_class: nil,
      label: "Loading form"
    )
      @fields = fields
      @with_actions = with_actions
      @with_cancel = with_cancel
      @css_class = css_class
      @label = label
    end

    def call
      tag.div(
        class: class_names("space-y-4", @css_class),
        role: "status",
        "aria-label": @label
      ) do
        safe_join([
          render_fields,
          render_actions,
          tag.span("#{@label}...", class: "sr-only")
        ].compact)
      end
    end

    private

    def render_fields
      if @fields.is_a?(Array)
        safe_join(@fields.map { |type| render_field(type) })
      else
        safe_join(@fields.times.map { render_field(:input) })
      end
    end

    def render_field(type = :input)
      config = FIELD_TYPES[type] || FIELD_TYPES[:input]

      tag.div(class: "form-control") do
        safe_join([
          tag.label(class: "label") { tag.div(class: "skeleton h-4 w-24") },
          if type == :checkbox
            tag.div(class: "flex items-center gap-3") do
              safe_join([
                tag.div(class: "skeleton #{config[:height]} #{config[:width]} rounded"),
                tag.div(class: "skeleton h-4 w-32")
              ])
            end
          else
            tag.div(class: "skeleton #{config[:height]} w-full rounded-lg")
          end
        ])
      end
    end

    def render_actions
      return nil unless @with_actions

      tag.div(class: "pt-4 flex justify-end gap-2") do
        safe_join([
          @with_cancel ? tag.div(class: "skeleton h-10 w-24 rounded-lg") : nil,
          tag.div(class: "skeleton h-10 w-32 rounded-lg")
        ].compact)
      end
    end
  end
end
