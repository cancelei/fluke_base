# frozen_string_literal: true

module Ui
  class PaginationComponent < ApplicationComponent
    include Pagy::Frontend

    def initialize(pagy:, remote: false, css_class: nil)
      @pagy = pagy
      @remote = remote
      @css_class = css_class
    end

    def render?
      @pagy && multiple_pages?
    end

    def call
      tag.div(class: @css_class) do
        tag.div(class: container_classes) do
          pagy_nav(@pagy).html_safe
        end
      end
    end

    private

    def multiple_pages?
      @pagy.pages > 1
    end

    def container_classes
      "bg-white/95 backdrop-blur-md shadow-lg ring-1 ring-gray-200/50 border border-gray-100 rounded-2xl px-6 py-4"
    end
  end
end
