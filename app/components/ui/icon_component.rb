# frozen_string_literal: true

module Ui
  class IconComponent < ApplicationComponent
    ICONS = {
      plus: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      edit: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" }
        ]
      },
      trash: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      eye: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M10 12a2 2 0 100-4 2 2 0 000 4z" },
          { d: "M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      message: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M2 5a2 2 0 012-2h7a2 2 0 012 2v4a2 2 0 01-2 2H9l-3 3v-3H4a2 2 0 01-2-2V5z" },
          { d: "M15 7v2a4 4 0 01-4 4H9.828l-1.766 1.767c.28.149.599.233.938.233h2l3 3v-3h2a2 2 0 002-2V9a2 2 0 00-2-2h-1z" }
        ]
      },
      lock: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      github: {
        viewbox: "0 0 24 24",
        paths: [
          { d: "M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.1-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      "exclamation-triangle": {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      check: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      x: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      folder: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M2 6a2 2 0 012-2h5l2 2h5a2 2 0 012 2v6a2 2 0 01-2 2H4a2 2 0 01-2-2V6z" }
        ]
      },
      chevron_down: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ],
        stroke: true
      },
      chevron_right: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      chevron_left: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      home: {
        viewbox: "0 0 24 24",
        paths: [
          { d: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" }
        ],
        stroke: true
      },
      search: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      user: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      users: {
        viewbox: "0 0 24 24",
        paths: [
          { d: "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" }
        ],
        stroke: true
      },
      cog: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      bell: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z" }
        ]
      },
      info: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      document: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M9 2a2 2 0 00-2 2v8a2 2 0 002 2h6a2 2 0 002-2V6.414A2 2 0 0016.414 5L14 2.586A2 2 0 0012.586 2H9z" },
          { d: "M3 8a2 2 0 012-2v10h8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z" }
        ]
      },
      calendar: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      },
      clock: {
        viewbox: "0 0 20 20",
        paths: [
          { d: "M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z", fill_rule: "evenodd", clip_rule: "evenodd" }
        ]
      }
    }.freeze

    SIZES = {
      xs: "h-3 w-3",
      sm: "h-4 w-4",
      md: "h-5 w-5",
      lg: "h-6 w-6",
      xl: "h-8 w-8"
    }.freeze

    def initialize(name:, size: :md, css_class: nil, **options)
      @name = name.to_s.gsub("-", "_").to_sym
      @size = size.to_sym
      @css_class = css_class
      @options = options
    end

    def call
      return "".html_safe unless icon_data

      tag.svg(
        class: combined_classes,
        fill: fill_attribute,
        viewBox: icon_data[:viewbox],
        stroke: stroke_attribute,
        **aria_attributes
      ) do
        render_paths
      end
    end

    def render?
      @name.present? && icon_data.present?
    end

    private

    def icon_data
      # Try both the direct name and with underscores converted to hyphens
      ICONS[@name] || ICONS[@name.to_s.gsub("_", "-").to_sym]
    end

    def combined_classes
      class_names(SIZES[@size], @css_class)
    end

    def fill_attribute
      icon_data[:stroke] ? "none" : "currentColor"
    end

    def stroke_attribute
      icon_data[:stroke] ? "currentColor" : nil
    end

    def aria_attributes
      { "aria-hidden": "true", role: "img" }
    end

    def render_paths
      safe_join(icon_data[:paths].map do |path_data|
        path_attrs = { d: path_data[:d] }
        path_attrs["fill-rule"] = path_data[:fill_rule] if path_data[:fill_rule]
        path_attrs["clip-rule"] = path_data[:clip_rule] if path_data[:clip_rule]
        tag.path(**path_attrs)
      end)
    end
  end
end
