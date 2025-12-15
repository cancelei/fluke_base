# frozen_string_literal: true

module Ui
  class PaginationComponent < ApplicationComponent
    def initialize(records:, remote: false, css_class: nil)
      @records = records
      @remote = remote
      @css_class = css_class
    end

    def render?
      paginated? && multiple_pages?
    end

    def call
      tag.div(class: @css_class) do
        tag.div(class: container_classes) do
          helpers.paginate(@records, remote: @remote)
        end
      end
    end

    private

    def paginated?
      @records.respond_to?(:total_pages)
    end

    def multiple_pages?
      @records.total_pages > 1
    end

    def container_classes
      "bg-white/95 backdrop-blur-md shadow-lg ring-1 ring-gray-200/50 border border-gray-100 rounded-2xl px-6 py-4"
    end
  end
end
