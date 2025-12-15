module Users
  class PreferencesController < ApplicationController
    skip_before_action :authenticate_user!, only: [ :update_theme ]

    def update_theme
      service = ThemePreferenceService.new(current_user, session, params[:theme])

      if service.call
        respond_to do |format|
          format.json { render json: { theme: service.theme }, status: :ok }
          format.html { redirect_back fallback_location: root_path }
        end
      else
        respond_to do |format|
          format.json { render json: { error: "Invalid theme" }, status: :unprocessable_entity }
          format.html { redirect_back fallback_location: root_path, alert: "Invalid theme" }
        end
      end
    end
  end
end
