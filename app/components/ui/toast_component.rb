# frozen_string_literal: true

module Ui
  class ToastComponent < ApplicationComponent
    # Use shared constants for consistency across components
    TYPE_MAPPING = SharedConstants::TYPE_MAPPING
    ALERT_CLASSES = SharedConstants::ALERT_CLASSES
    POSITIONS = SharedConstants::TOAST_POSITIONS

    def initialize(
      type:,
      message:,
      title: nil,
      timeout: 5000,
      close_button: true,
      position: "toast-top-right"
    )
      @type = normalize_type(type)
      @message = message
      @title = title
      @timeout = timeout
      @close_button = close_button
      @position = position
    end

    def render?
      @message.present?
    end

    def call
      tag.div(class: position_class, data: stimulus_data) do
        tag.div(class: alert_classes, role: "alert") do
          safe_join([
            render_icon,
            render_content,
            render_close_button
          ].compact)
        end
      end
    end

    private

    def normalize_type(type)
      TYPE_MAPPING[type.to_s.downcase.to_sym] || :info
    end

    def position_class
      POSITIONS[@position] || "toast toast-top toast-end"
    end

    def alert_classes
      "alert #{ALERT_CLASSES[@type]} shadow-lg"
    end

    def stimulus_data
      {
        controller: "toast",
        "toast-timeout-value": @timeout
      }
    end

    def render_icon
      icon_path = SharedConstants::NOTIFICATION_ICON_PATHS[@type] ||
                  SharedConstants::NOTIFICATION_ICON_PATHS[:info]

      tag.svg(
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-6 w-6 shrink-0 stroke-current",
        fill: "none",
        viewBox: "0 0 24 24"
      ) do
        tag.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2",
          d: icon_path
        )
      end
    end

    def render_content
      tag.div do
        safe_join([
          (@title.present? ? tag.h3(@title, class: "font-bold") : nil),
          tag.span(sanitized_message)
        ].compact)
      end
    end

    def render_close_button
      return unless @close_button

      tag.button(class: "btn btn-sm btn-ghost", data: { action: "toast#dismiss" }) do
        tag.svg(
          xmlns: "http://www.w3.org/2000/svg",
          class: "h-4 w-4",
          fill: "none",
          viewBox: "0 0 24 24",
          stroke: "currentColor"
        ) do
          tag.path(
            stroke_linecap: "round",
            stroke_linejoin: "round",
            stroke_width: "2",
            d: SharedConstants::CLOSE_ICON_PATH
          )
        end
      end
    end

    def sanitized_message
      if @message.to_s.include?("<a ")
        ActionController::Base.helpers.sanitize(
          @message.to_s,
          tags: %w[a],
          attributes: %w[href title target rel class]
        ).html_safe
      else
        ERB::Util.html_escape(@message.to_s)
      end
    end
  end
end
