# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  # CSS class builder for cleaner conditional classes
  def class_names(*classes)
    classes.flatten.compact.reject(&:blank?).join(" ")
  end

  private

  # Default URL options for route helpers
  def default_url_options
    Rails.application.config.action_mailer.default_url_options || {}
  end
end
