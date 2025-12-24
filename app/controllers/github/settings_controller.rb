# frozen_string_literal: true

module Github
  # Handles GitHub App connection settings
  #
  # Provides endpoints for:
  # - Disconnecting GitHub account
  # - Viewing connected installations
  # - Checking repository access
  #
  class SettingsController < ApplicationController
    before_action :authenticate_user!

    # DELETE /github/disconnect
    # Disconnects the user's GitHub account and removes all installations
    def disconnect
      current_user.disconnect_github_app!

      respond_to do |format|
        format.html do
          flash[:success] = "GitHub account disconnected successfully."
          redirect_to edit_profile_path
        end
        format.json { render json: { status: "disconnected" } }
      end
    end

    # GET /github/installations
    # Returns list of user's GitHub App installations
    def installations
      @installations = current_user.github_app_installations.includes(:user)

      respond_to do |format|
        format.html { render partial: "github/installations", locals: { installations: @installations } }
        format.json do
          render json: @installations.map { |i|
            {
              id: i.id,
              installation_id: i.installation_id,
              account_login: i.account_login,
              account_type: i.account_type,
              repositories: i.accessible_repos,
              installed_at: i.installed_at
            }
          }
        end
      end
    end

    # GET /github/check_access?repository_url=owner/repo
    # Checks if the user has access to a specific repository
    def check_access
      repository_url = params[:repository_url]

      if repository_url.blank?
        render json: { error: "repository_url is required" }, status: :bad_request
        return
      end

      result = ::Github::RepositoryAccessChecker.call(
        user: current_user,
        repository_url:
      )

      if result.success?
        render json: result.value!
      else
        render json: result.failure, status: :unprocessable_entity
      end
    end
  end
end
