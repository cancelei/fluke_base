# frozen_string_literal: true

module Ui
  class FormErrorsComponent < ApplicationComponent
    def initialize(object:)
      @object = object
    end

    def render?
      @object&.errors&.any?
    end

    def call
      tag.div(class: container_classes) do
        tag.div(class: "flex") do
          safe_join([ render_icon, render_content ])
        end
      end
    end

    private

    def container_classes
      "bg-red-50 border border-red-200 rounded-md p-4 mb-6"
    end

    def render_icon
      tag.div(class: "flex-shrink-0") do
        render(Ui::IconComponent.new(
          name: "exclamation-triangle",
          size: :md,
          css_class: "text-red-400"
        ))
      end
    end

    def render_content
      tag.div(class: "ml-3") do
        safe_join([ render_header, render_errors ])
      end
    end

    def render_header
      model_name = @object.class.model_name.human.downcase
      tag.h3(class: "text-sm font-medium text-red-800") do
        "#{helpers.pluralize(@object.errors.count, 'error')} prohibited this #{model_name} from being saved:"
      end
    end

    def render_errors
      tag.div(class: "mt-2 text-sm text-red-700") do
        tag.ul(class: "list-disc pl-5 space-y-1") do
          safe_join(@object.errors.full_messages.map { |msg| tag.li(msg) })
        end
      end
    end
  end
end
