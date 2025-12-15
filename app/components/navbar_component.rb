# frozen_string_literal: true

# NavbarComponent wraps the existing navbar partial for ViewComponent interface
# The actual rendering delegates to the partial due to its complexity
class NavbarComponent < ApplicationComponent
  def initialize(current_user: nil)
    @current_user = current_user
  end

  def call
    helpers.render(partial: "shared/navbar")
  end
end
