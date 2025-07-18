# frozen_string_literal: true

Kaminari.configure do |config|
  # Default number of items per page
  config.default_per_page = 12

  # Maximum number of items per page
  config.max_per_page = 100

  # Number of pages to show on each side of current page
  config.window = 2

  # Number of pages to show at the beginning and end of pagination
  config.outer_window = 1

  # Method name for fetching the current page number
  config.page_method_name = :page

  # Parameter name for page number in URLs
  config.param_name = :page

  # Whether to include page parameter even on the first page
  config.params_on_first_page = false
end
