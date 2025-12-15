# frozen_string_literal: true

# Configure FlukeFormBuilder as the default form builder
# This provides automatic loading state support via submit_button method
Rails.application.config.to_prepare do
  Rails.application.config.action_view.default_form_builder = FlukeFormBuilder
end
