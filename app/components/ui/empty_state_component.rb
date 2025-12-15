# frozen_string_literal: true

module Ui
  class EmptyStateComponent < ApplicationComponent
    def initialize(
      title:,
      description:,
      icon: :folder,
      action_text: nil,
      action_url: nil,
      action_variant: :primary,
      action_icon: :plus,
      css_class: nil
    )
      @title = title
      @description = description
      @icon = icon
      @action_text = action_text
      @action_url = action_url
      @action_variant = action_variant
      @action_icon = action_icon
      @css_class = css_class
    end

    def call
      tag.div(class: container_classes) do
        safe_join([
          render_icon,
          render_title,
          render_description,
          render_action,
          (content if content?)
        ].compact)
      end
    end

    private

    def container_classes
      class_names("text-center py-12", @css_class)
    end

    def render_icon
      tag.div(class: "mx-auto h-12 w-12 text-gray-400") do
        render(Ui::IconComponent.new(name: @icon, size: :xl, css_class: "mx-auto h-12 w-12"))
      end
    end

    def render_title
      tag.h3(@title, class: "mt-2 text-sm font-medium text-gray-900")
    end

    def render_description
      tag.p(@description, class: "mt-1 text-sm text-gray-500")
    end

    def render_action
      return unless @action_text && @action_url

      tag.div(class: "mt-6") do
        render(Ui::ButtonComponent.new(
          text: @action_text,
          url: @action_url,
          variant: @action_variant,
          icon: @action_icon
        ))
      end
    end
  end
end
