# frozen_string_literal: true

module Ui
  class LoadingPlaceholderComponent < ApplicationComponent
    def initialize(title: nil, description: nil, css_class: nil, variant: :default)
      @title = title
      @description = description
      @css_class = css_class
      @variant = variant
    end

    def call
      tag.div(class: container_classes) do
        if @title.present?
          safe_join([ render_header, render_loading ])
        else
          render_loading
        end
      end
    end

    private

    def container_classes
      class_names("card bg-base-100 shadow-xl", @css_class)
    end

    def render_header
      tag.div(class: "card-body pb-0") do
        tag.div do
          safe_join([
            tag.h3(@title, class: "card-title"),
            tag.p(@description, class: "text-sm opacity-70")
          ].compact)
        end
      end
    end

    def render_loading
      tag.div(class: "card-body") do
        tag.div(class: "flex flex-col items-center justify-center py-8") do
          safe_join([
            render_spinner,
            tag.p("Loading content...", class: "mt-3 text-sm opacity-60")
          ])
        end
      end
    end

    def render_spinner
      spinner_classes = case @variant
      when :primary then "loading loading-spinner loading-lg text-primary"
      when :secondary then "loading loading-spinner loading-lg text-secondary"
      when :dots then "loading loading-dots loading-lg"
      when :ring then "loading loading-ring loading-lg"
      when :ball then "loading loading-ball loading-lg"
      when :bars then "loading loading-bars loading-lg"
      when :infinity then "loading loading-infinity loading-lg"
      else "loading loading-spinner loading-lg text-primary"
      end

      tag.span(class: spinner_classes, role: "status", "aria-label": "loading") do
        tag.span("Loading...", class: "sr-only")
      end
    end
  end
end
