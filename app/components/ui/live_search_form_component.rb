# frozen_string_literal: true

module Ui
  class LiveSearchFormComponent < ApplicationComponent
    # Supported filter types
    FILTER_TYPES = %i[text select date hidden].freeze

    # @param url [String] Form action URL
    # @param turbo_frame [String, nil] Target Turbo frame ID for results
    # @param search_placeholder [String] Placeholder for search input
    # @param search_name [Symbol] Name of the search parameter (default: :search)
    # @param filters [Array<Hash>] Array of filter configurations
    # @param hidden_fields [Hash] Hidden fields to include in the form
    # @param debounce [Integer] Debounce delay in milliseconds (default: 400)
    # @param min_length [Integer] Minimum characters before searching (default: 0)
    # @param show_submit [Boolean] Show submit button (default: false)
    # @param submit_text [String] Text for submit button
    # @param form_class [String] CSS classes for the form
    # @param input_class [String] CSS classes for inputs
    # @param params [Hash] Current request params for preserving values
    # @param css_class [String] Additional wrapper CSS classes
    def initialize(
      url:,
      turbo_frame: nil,
      search_placeholder: "Search...",
      search_name: :search,
      filters: [],
      hidden_fields: {},
      debounce: 400,
      min_length: 0,
      show_submit: false,
      submit_text: "Search",
      form_class: "flex flex-wrap items-end gap-3",
      input_class: nil,
      params: {},
      css_class: nil
    )
      @url = url
      @turbo_frame = turbo_frame
      @search_placeholder = search_placeholder
      @search_name = search_name
      @filters = filters
      @hidden_fields = hidden_fields
      @debounce = debounce
      @min_length = min_length
      @show_submit = show_submit
      @submit_text = submit_text
      @form_class = form_class
      @input_class = input_class || "input input-bordered"
      @params = params.to_h.with_indifferent_access
      @css_class = css_class
    end

    def form_data_attributes
      attrs = {
        controller: "live-search",
        "live-search-debounce-value": @debounce,
        "live-search-min-length-value": @min_length
      }
      attrs[:turbo_frame] = @turbo_frame if @turbo_frame
      attrs
    end

    def search_value
      @params[@search_name]
    end

    def filter_value(filter)
      @params[filter[:name]]
    end

    def text_input_class
      class_names(@input_class, "flex-1 min-w-[200px]")
    end

    def select_input_class
      class_names("select select-bordered", filter_width_class)
    end

    def date_input_class
      class_names(@input_class)
    end

    def filter_width_class
      "min-w-[150px]"
    end

    def submit_button_class
      class_names("btn btn-primary", @show_submit ? "" : "hidden")
    end

    def has_active_filters?
      search_value.present? || @filters.any? { |f| filter_value(f).present? }
    end

    def active_filters_count
      count = search_value.present? ? 1 : 0
      count + @filters.count { |f| filter_value(f).present? }
    end
  end
end
