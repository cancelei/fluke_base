# frozen_string_literal: true

module Ui
  class SocialLinksComponent < ApplicationComponent
    PLATFORMS = {
      linkedin: {
        base_url: "https://linkedin.com/in/",
        label: "LinkedIn",
        btn_class: "btn-info btn-outline",
        icon_path: "M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"
      },
      x: {
        base_url: "https://x.com/",
        label: "X",
        btn_class: "btn-ghost",
        icon_path: "M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
      },
      instagram: {
        base_url: "https://instagram.com/",
        label: "Instagram",
        btn_class: "btn-secondary btn-outline",
        icon_path: "M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"
      },
      youtube: {
        base_url: "https://youtube.com/",
        label: "YouTube",
        btn_class: "btn-error btn-outline",
        icon_path: "M19.615 3.184c-3.604-.246-11.631-.245-15.23 0-3.897.266-4.356 2.62-4.385 8.816.029 6.185.484 8.549 4.385 8.816 3.6.245 11.626.246 15.23 0 3.897-.266 4.356-2.62 4.385-8.816-.029-6.185-.484-8.549-4.385-8.816zm-10.615 12.816v-8l8 3.993-8 4.007z"
      },
      facebook: {
        base_url: "https://facebook.com/",
        label: "Facebook",
        btn_class: "btn-info btn-outline",
        icon_path: "M9 8h-3v4h3v12h5v-12h3.642l.358-4h-4v-1.667c0-.955.192-1.333 1.115-1.333h2.885v-5h-3.808c-3.596 0-5.192 1.583-5.192 4.615v3.385z"
      },
      tiktok: {
        base_url: "https://tiktok.com/@",
        label: "TikTok",
        btn_class: "btn-neutral",
        icon_path: "M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-5.2 1.74 2.89 2.89 0 012.31-4.64 2.93 2.93 0 01.88.13V9.4a6.84 6.84 0 00-1-.05A6.33 6.33 0 005 20.1a6.34 6.34 0 0010.86-4.43v-7a8.16 8.16 0 004.77 1.52v-3.4a4.85 4.85 0 01-1-.1z"
      },
      github: {
        base_url: "https://github.com/",
        label: "GitHub",
        btn_class: "btn-neutral btn-outline",
        icon_path: "M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.1-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
      }
    }.freeze

    VARIANTS = {
      buttons: { size: "btn-sm", wrapper_class: "flex flex-wrap gap-2", type: :button },
      inline: { size: "btn-xs", wrapper_class: "flex flex-wrap gap-1", type: :button },
      icons_only: { size: "btn-sm btn-circle", wrapper_class: "flex gap-1", type: :button },
      badges: { size: "", wrapper_class: "flex flex-wrap gap-2", type: :badge }
    }.freeze

    BADGE_CLASSES = {
      linkedin: "badge badge-info",
      x: "badge badge-ghost",
      instagram: "badge badge-secondary",
      youtube: "badge badge-error",
      facebook: "badge badge-info",
      tiktok: "badge badge-neutral",
      github: "badge badge-neutral"
    }.freeze

    def initialize(user:, variant: :buttons, show_header: false, header_text: "Connect", platforms: nil)
      @user = user
      @variant = variant.to_sym
      @show_header = show_header
      @header_text = header_text
      @platforms = platforms || PLATFORMS.keys
    end

    def call
      return "".html_safe unless any_links_present?

      if @show_header
        render_with_header
      else
        render_links_only
      end
    end

    def render?
      @user.present? && any_links_present?
    end

    private

    def any_links_present?
      @platforms.any? { |platform| user_has_link?(platform) }
    end

    def user_has_link?(platform)
      @user.respond_to?(platform) && @user.send(platform).present?
    end

    def variant_config
      VARIANTS[@variant] || VARIANTS[:buttons]
    end

    def render_with_header
      tag.div(class: "bg-info/10 border border-info/20 rounded-box p-4") do
        safe_join([
          render_header,
          render_links_only
        ])
      end
    end

    def render_header
      tag.h3(class: "text-sm font-bold text-info mb-3 flex items-center") do
        safe_join([
          render_connect_icon,
          @header_text
        ])
      end
    end

    def render_connect_icon
      tag.svg(class: "h-4 w-4 mr-2", fill: "currentColor", viewBox: "0 0 24 24", "aria-hidden": "true") do
        tag.path(d: "M22.675 0h-21.35c-.732 0-1.325.593-1.325 1.325v21.351c0 .731.593 1.324 1.325 1.324h21.351c.731 0 1.324-.593 1.324-1.324v-21.351c0-.732-.593-1.325-1.325-1.325zm-11.676 9h-2v-3h2v3zm0 11h-2v-9h2v9zm9 0h-7v-1.5h7v1.5zm0-4h-7v-1.5h7v1.5zm0-4h-7v-1.5h7v1.5z")
      end
    end

    def render_links_only
      tag.div(class: variant_config[:wrapper_class]) do
        safe_join(
          @platforms.filter_map { |platform| render_link(platform) if user_has_link?(platform) }
        )
      end
    end

    def render_link(platform)
      config = PLATFORMS[platform]
      return unless config

      username = @user.send(platform)
      url = "#{config[:base_url]}#{username}"

      tag.a(
        href: url,
        target: "_blank",
        rel: "noopener noreferrer",
        "aria-label": "Visit #{user_name}'s #{config[:label]} profile",
        class: link_classes(config)
      ) do
        safe_join([
          render_platform_icon(config[:icon_path]),
          render_label(config[:label])
        ])
      end
    end

    def link_classes(config)
      if variant_config[:type] == :badge
        platform_key = PLATFORMS.find { |k, v| v == config }&.first
        badge_class = BADGE_CLASSES[platform_key] || "badge"
        class_names(badge_class, "gap-1 hover:brightness-90 transition-colors")
      else
        base = "btn gap-1"
        size = variant_config[:size]
        style = config[:btn_class]
        class_names(base, size, style)
      end
    end

    def render_platform_icon(path)
      icon_size = variant_config[:type] == :badge ? "h-3 w-3" : "h-4 w-4"
      tag.svg(class: icon_size, fill: "currentColor", viewBox: "0 0 24 24", "aria-hidden": "true") do
        tag.path(d: path)
      end
    end

    def render_label(label)
      return "".html_safe if @variant == :icons_only

      label
    end

    def user_name
      @user.respond_to?(:full_name) ? @user.full_name : "User"
    end
  end
end
