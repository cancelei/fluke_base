# frozen_string_literal: true

module Ui
  # Modal Component using native HTML dialog element
  #
  # DaisyUI v5 recommended pattern for modals using the native <dialog> element.
  # Provides better accessibility and browser support compared to checkbox-based modals.
  #
  # Usage:
  #   <%= render Ui::ModalComponent.new(id: "my-modal", title: "Modal Title") do %>
  #     <p>Modal content here</p>
  #   <% end %>
  #
  # Opening the modal (JavaScript):
  #   document.getElementById('my-modal').showModal()
  #
  # Or with a button:
  #   <button onclick="document.getElementById('my-modal').showModal()">Open</button>
  #
  class ModalComponent < ApplicationComponent
    SIZES = {
      xs: "max-w-xs",
      sm: "max-w-sm",
      md: "max-w-md",
      lg: "max-w-lg",
      xl: "max-w-xl",
      full: "max-w-full mx-4"
    }.freeze

    POSITIONS = {
      middle: "modal-middle",
      top: "modal-top",
      bottom: "modal-bottom"
    }.freeze

    # @param id [String] Unique identifier for the modal (required)
    # @param title [String, nil] Optional title displayed in the modal header
    # @param size [Symbol] Size of the modal (:xs, :sm, :md, :lg, :xl, :full)
    # @param position [Symbol] Vertical position (:middle, :top, :bottom)
    # @param closeable [Boolean] Whether to show close button and allow backdrop close
    # @param close_button_text [String] Text for the close button
    # @param classes [String] Additional CSS classes for the modal-box
    def initialize(
      id:,
      title: nil,
      size: :md,
      position: :middle,
      closeable: true,
      close_button_text: "Close",
      classes: ""
    )
      @id = id
      @title = title
      @size = size
      @position = position
      @closeable = closeable
      @close_button_text = close_button_text
      @classes = classes
    end

    def call
      tag.dialog(
        id: @id,
        class: modal_classes,
        data: { controller: "modal" }
      ) do
        safe_join([
          render_modal_box,
          render_backdrop
        ].compact)
      end
    end

    private

    def modal_classes
      class_names("modal", POSITIONS[@position])
    end

    def modal_box_classes
      class_names(
        "modal-box",
        SIZES[@size],
        @classes
      )
    end

    def render_modal_box
      tag.div(class: modal_box_classes) do
        safe_join([
          render_close_button_top,
          render_title,
          render_content,
          render_actions
        ].compact)
      end
    end

    def render_close_button_top
      return unless @closeable

      tag.form(method: "dialog") do
        tag.button(
          class: "btn btn-sm btn-circle btn-ghost absolute right-2 top-2",
          "aria-label": "Close modal"
        ) do
          tag.svg(
            class: "w-4 h-4",
            fill: "none",
            stroke: "currentColor",
            viewBox: "0 0 24 24"
          ) do
            tag.path(
              "stroke-linecap": "round",
              "stroke-linejoin": "round",
              "stroke-width": "2",
              d: "M6 18L18 6M6 6l12 12"
            )
          end
        end
      end
    end

    def render_title
      return unless @title

      tag.h3(class: "text-lg font-bold mb-4") { @title }
    end

    def render_content
      tag.div(class: "py-2") { content }
    end

    def render_actions
      return unless @closeable

      tag.div(class: "modal-action") do
        tag.form(method: "dialog") do
          tag.button(class: "btn") { @close_button_text }
        end
      end
    end

    def render_backdrop
      return unless @closeable

      tag.form(method: "dialog", class: "modal-backdrop") do
        tag.button("close", "aria-label": "Close modal")
      end
    end
  end
end
