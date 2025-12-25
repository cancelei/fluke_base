# frozen_string_literal: true

module Users
  # Handles GitHub OAuth callbacks from OmniAuth
  #
  # This controller handles:
  # - New user signups via GitHub (creates account from GitHub data)
  # - Existing user logins via GitHub
  # - Linking GitHub to signed-in users
  # - Session restoration for returning GitHub users
  #
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :authenticate_user!, only: [:github, :failure]

    # Cookie name for tracking GitHub auth preference
    GITHUB_AUTH_COOKIE = :github_auth_preferred

    # GitHub OAuth callback
    # Called after user authorizes FlukeBase on GitHub
    def github
      auth = request.env["omniauth.auth"]

      # Check for OAuth errors (e.g., rate limits, API issues)
      if auth.nil?
        error = request.env["omniauth.error"]
        handle_oauth_error(error)
        return
      end

      # Get a valid email address from GitHub
      # Handles private emails by checking verified emails list
      email = extract_verified_email(auth)

      unless email.present?
        flash[:error] = "Could not get a verified email from GitHub. Please ensure you have " \
                        "at least one verified email on your GitHub account, or sign up with email."
        redirect_to new_user_registration_path
        return
      end

      # Store the resolved email for downstream processing
      auth.info.email = email

      if current_user
        # User is signed in - link GitHub to their account
        link_github_to_current_user(auth)
      else
        # User is not signed in - find or create user
        handle_github_signup_or_login(auth)
      end
    rescue OAuth2::Error => e
      handle_oauth_error(e)
    end

    # OAuth failure callback
    def failure
      raw_error = failure_message || "Unknown error"
      Rails.logger.warn "[OmniAuth] GitHub authentication failed: #{raw_error}"

      # Parse the error and show user-friendly message
      flash[:error] = friendly_error_message(raw_error)
      redirect_to after_omniauth_failure_path_for(resource_name)
    end

    protected

    def after_omniauth_failure_path_for(_scope)
      new_user_registration_path
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
      Github::AppConfig.install_url
    end

    def failure_message
      params[:message] || request.env["omniauth.error"]&.message
    end

    def friendly_error_message(raw_error)
      error_string = raw_error.to_s.downcase

      if error_string.include?("rate limit")
        "GitHub API rate limit exceeded. Please wait a few minutes and try again, or sign up with email."
      elsif error_string.include?("403") || error_string.include?("forbidden")
        "GitHub access was denied. Please try again or sign up with email."
      elsif error_string.include?("401") || error_string.include?("unauthorized")
        "GitHub authentication failed. Please try again."
      elsif error_string.include?("timeout") || error_string.include?("timed out")
        "GitHub is taking too long to respond. Please try again."
      elsif error_string.include?("invalid_credentials")
        "Invalid GitHub credentials. Please try again."
      elsif error_string.include?("access_denied")
        "You denied access to your GitHub account. Sign up with email instead."
      else
        "GitHub connection failed. Please try again or sign up with email."
      end
    end

    def handle_oauth_error(error)
      raw_error = error&.message || "Unknown error"
      Rails.logger.error "[OmniAuth] GitHub OAuth error: #{raw_error}"

      flash[:error] = friendly_error_message(raw_error)
      redirect_to new_user_registration_path
    end

    # Extract a usable email from GitHub OAuth response
    # Handles private emails by:
    # 1. Using primary email from auth.info.email if valid
    # 2. Falling back to verified emails from auth.extra.all_emails
    # 3. Rejecting noreply@github.com addresses for account creation
    #
    # The user:email scope provides access to verified emails even when
    # the user has "Keep my email address private" enabled.
    def extract_verified_email(auth)
      # First try the primary email
      primary_email = auth.info&.email

      # Check if it's a valid, non-noreply email
      if primary_email.present? && !github_noreply_email?(primary_email)
        return primary_email
      end

      # If primary is noreply or missing, check verified emails
      # (requires user:email scope)
      all_emails = auth.extra&.all_emails || auth.extra&.raw_info&.emails || []

      # Find the first verified, non-noreply email
      # Prefer primary if available
      verified_email = all_emails
        .select { |e| e[:verified] || e["verified"] }
        .reject { |e| github_noreply_email?(e[:email] || e["email"]) }
        .sort_by { |e| (e[:primary] || e["primary"]) ? 0 : 1 }
        .first

      email = verified_email&.dig(:email) || verified_email&.dig("email")

      if email.blank? && primary_email.present?
        # Fall back to noreply if that's all we have
        # This allows login for existing users, but new signups will need to
        # provide an email manually
        Rails.logger.info "[OmniAuth] Using GitHub noreply email as fallback: #{primary_email}"
        return primary_email
      end

      email
    end

    # Check if email is a GitHub noreply address
    def github_noreply_email?(email)
      return false if email.blank?

      email.end_with?("@users.noreply.github.com") ||
        email == "noreply@github.com"
    end

    def handle_github_signup_or_login(auth)
      result = User.from_github_omniauth(auth)
      user = result[:user]
      created = result[:created]
      linked = result[:linked]
      session_restored = session.delete(:github_session_restore)

      if user.persisted?
        # Set persistent cookie to remember GitHub auth preference (30 days)
        set_github_auth_cookie

        sign_in_and_redirect user, event: :authentication

        if created
          flash[:success] = "Welcome to FlukeBase! Your account has been created with GitHub."
        elsif linked
          # Existing email account was linked to GitHub for the first time
          flash[:info] = "Your GitHub account has been linked to your existing FlukeBase account. " \
                         "You can now sign in with either your email or GitHub."
        elsif session_restored
          # Session was automatically restored
          flash[:success] = "Welcome back! You've been automatically signed in with GitHub."
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

    def set_github_auth_cookie
      cookies.signed[GITHUB_AUTH_COOKIE] = {
        value: true,
        expires: 30.days.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
    end
  end
end
