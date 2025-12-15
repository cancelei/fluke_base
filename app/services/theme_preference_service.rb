# frozen_string_literal: true

# Service for updating user theme preference
class ThemePreferenceService < ApplicationService
  def initialize(user, session, theme)
    @user = user
    @session = session
    @theme = theme
  end

  # @return [Dry::Monads::Result] Success(theme) or Failure(error)
  def call
    return failure_result(:invalid_theme, "Invalid theme: #{@theme}") unless valid_theme?

    update_user_preference if @user
    update_session
    Success(@theme)
  end

  def theme
    @theme
  end

  private

  def valid_theme?
    User::AVAILABLE_THEMES.include?(@theme)
  end

  def update_user_preference
    @user.update(theme_preference: @theme)
  end

  def update_session
    @session[:theme_preference] = @theme
  end
end
