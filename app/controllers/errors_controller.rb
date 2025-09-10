class ErrorsController < ApplicationController
  # Skip authentication for error pages
  skip_before_action :authenticate_user!

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end

  def unsupported_browser
    render status: :not_acceptable
  end
end
