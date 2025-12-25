# frozen_string_literal: true

module Github
  # Handles GitHub App connection settings
  #
  # Provides endpoints for:
  # - Disconnecting GitHub account
  # - Viewing connected installations
  # - Checking repository access
  # - Session restoration for returning GitHub users
  #
  class SettingsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:session_restore]
    skip_before_action :attempt_github_session_restore, only: [:session_restore]

    # DELETE /github/disconnect
    # Disconnects the user's GitHub account and removes all installations
    def disconnect
      current_user.disconnect_github_app!

      respond_to do |format|
        format.html do
          flash[:success] = "GitHub account disconnected successfully."
          # Use status: :see_other (303) for Turbo to properly follow the redirect
          redirect_to edit_profile_path, status: :see_other
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

    # GET /github/session_restore
    # Renders an intermediate page that auto-submits the GitHub OAuth form
    # This is needed because OmniAuth requires POST for CSRF protection
    def session_restore
      # If user is already signed in, redirect to dashboard
      if user_signed_in?
        redirect_to dashboard_path
        return
      end

      # Render the auto-submit form page
      render layout: "minimal"
    end
  end
end
