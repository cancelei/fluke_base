# frozen_string_literal: true

module Users
  # Handles GitHub OAuth callbacks from OmniAuth
  #
  # This controller handles:
  # - New user signups via GitHub (creates account from GitHub data)
  # - Existing user logins via GitHub
  # - Linking GitHub to signed-in users
  #
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :authenticate_user!, only: [:github, :failure]

    # GitHub OAuth callback
    # Called after user authorizes FlukeBase on GitHub
    def github
      auth = request.env["omniauth.auth"]

      # Validate we have required data from GitHub
      unless auth&.info&.email.present?
        flash[:error] = "Could not get your email from GitHub. Please ensure your email is public or try signing up with email."
        redirect_to new_user_registration_path
        return
      end

      if current_user
        # User is signed in - link GitHub to their account
        link_github_to_current_user(auth)
      else
        # User is not signed in - find or create user
        handle_github_signup_or_login(auth)
      end
    end

    # OAuth failure callback
    def failure
      error_message = failure_message || "Unknown error"
      Rails.logger.warn "[OmniAuth] GitHub authentication failed: #{error_message}"

      flash[:error] = "GitHub connection failed: #{error_message}"
      redirect_to after_omniauth_failure_path_for(resource_name)
    end

    protected

    def after_omniauth_failure_path_for(_scope)
      root_path
    end

    private

    def link_github_to_current_user(auth)
      # Check if this GitHub account is already linked to another user
      existing_user = User.find_by(github_uid: auth.uid)

      if existing_user && existing_user != current_user
        flash[:error] = "This GitHub account is already connected to another FlukeBase account."
        redirect_to edit_profile_path
        return
      end

      # Link GitHub to current user
      current_user.update!(
        github_uid: auth.uid,
        github_user_access_token: auth.credentials.token,
        github_refresh_token: auth.credentials.refresh_token,
        github_token_expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil,
        github_username: auth.info.nickname,
        github_connected_at: Time.current
      )

      flash[:success] = "GitHub account connected successfully! Now install FlukeBase on your repositories."

      # Redirect to GitHub App installation page
      redirect_to github_app_install_url, allow_other_host: true
    end

    def github_app_install_url
      app_slug = Rails.application.credentials.dig(:github_app, :slug) || "flukebase"
      "https://github.com/apps/#{app_slug}/installations/new"
    end

    def failure_message
      params[:message] || request.env["omniauth.error"]&.message
    end

    def handle_github_signup_or_login(auth)
      result = User.from_github_omniauth(auth)
      user = result[:user]
      created = result[:created]

      if user.persisted?
        sign_in_and_redirect user, event: :authentication

        if created
          flash[:success] = "Welcome to FlukeBase! Your account has been created with GitHub."
        else
          set_flash_message(:notice, :success, kind: "GitHub") if is_navigational_format?
        end
      else
        # User creation failed - show errors
        session["devise.github_data"] = {
          email: auth.info.email,
          first_name: User.extract_name_from_github(auth)[:first_name],
          last_name: User.extract_name_from_github(auth)[:last_name],
          github_username: auth.info.nickname
        }
        flash[:error] = "Could not create account: #{user.errors.full_messages.join(', ')}"
        redirect_to new_user_registration_path
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[OmniAuth] Failed to create user from GitHub: #{e.message}"
      flash[:error] = "Could not create account: #{e.record.errors.full_messages.join(', ')}"
      redirect_to new_user_registration_path
    end
  end
end
