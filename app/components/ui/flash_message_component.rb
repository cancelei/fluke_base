# frozen_string_literal: true

module Ui
  class FlashMessageComponent < ApplicationComponent
    # Use shared constants for type mapping
    TYPE_MAPPING = SharedConstants::TYPE_MAPPING
    ALERT_CLASSES = SharedConstants::ALERT_CLASSES

    def initialize(type:, message:)
      @type = type.to_sym
      @normalized_type = SharedConstants.normalize_type(@type)
      @message = message
    end

    def render?
      @message.present?
    end

    def call
      tag.div(class: container_classes, role: "alert") do
        safe_join([render_icon, render_message])
      end
    end

    private

    def container_classes
      alert_class = ALERT_CLASSES[@normalized_type] || ALERT_CLASSES[:info]
      "alert #{alert_class} mb-6"
    end

    def render_icon
      icon_path = SharedConstants::NOTIFICATION_ICON_PATHS[@normalized_type] ||
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

    def render_message
      tag.span { sanitized_message }
    end

    def sanitized_message
      if @message.to_s.include?("<a ")
        sanitize(@message.to_s, tags: %w[a], attributes: %w[href title target rel class]).html_safe
      else
        ERB::Util.html_escape(@message.to_s)
      end
    end

    def sanitize(html, options = {})
      ActionController::Base.helpers.sanitize(html, options)
    end
  end
end
