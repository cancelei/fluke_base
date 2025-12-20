class ApplicationPresenter
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def initialize(object, view_context = nil)
    @object = object
    @view_context = view_context
  end

  # Delegate all missing methods to the wrapped object
  def method_missing(method_name, *, &)
    if @object.respond_to?(method_name)
      @object.send(method_name, *, &)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @object.respond_to?(method_name, include_private) || super
  end

  protected

  attr_reader :object, :view_context

  def h
    @view_context
  end
end
