class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!, if: :devise_controller?
  layout "error"

  def not_found
    render "errors/404", status: :not_found
  end

  def unprocessable_entity
    render "errors/422", status: :unprocessable_entity
  end

  def internal_server_error
    render "errors/500", status: :internal_server_error
  end
end
