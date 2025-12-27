# frozen_string_literal: true

# Handles automatic session restoration for users who previously authenticated with GitHub
#
# When a user who has previously signed in via GitHub returns to the site with an expired
# session, this concern automatically redirects them to GitHub OAuth to restore their session.
# This provides a seamless experience for GitHub users.
#
# How it works:
# 1. When a user authenticates via GitHub, a persistent cookie is set
# 2. When they return with an expired session, this concern detects the cookie
# 3. It redirects to an intermediate page that auto-submits the OAuth form
# 4. GitHub auto-approves if user is still logged in and already authorized
# 5. After successful auth, a "Welcome back!" message is shown
#
# Safety measures:
# - Only triggers for HTML requests (not API calls)
# - Respects explicit logout (cookie is cleared)
# - Prevents redirect loops with a session flag
# - Only triggers for GET requests to avoid interfering with form submissions
#
module GithubSessionRestoration
  extend ActiveSupport::Concern

  GITHUB_AUTH_COOKIE = :github_auth_preferred
  RESTORE_ATTEMPTED_KEY = :github_restore_attempted

  included do
    before_action :attempt_github_session_restore, unless: :user_signed_in?
  end

  private

  def attempt_github_session_restore
    return unless should_attempt_github_restore?

    # Mark that we're attempting restoration to prevent loops
    session[RESTORE_ATTEMPTED_KEY] = true
    session[:github_session_restore] = true

    # Store the intended destination
    session[:user_return_to] = request.fullpath if get_like_request?

    Rails.logger.info "[GithubSessionRestoration] Attempting session restore for returning GitHub user"

    # Redirect to the session restore page which will auto-submit the OAuth form
    redirect_to github_session_restore_path
  end

  def should_attempt_github_restore?
    # Only for HTML GET requests
    return false unless request.format.html? && get_like_request?

    # Don't restore if we already attempted (prevents loops)
    return false if session[RESTORE_ATTEMPTED_KEY]

    # Don't restore on auth-related pages (login, signup, OAuth callbacks)
    return false if auth_related_path?

    # Check if user has the GitHub auth preference cookie
    cookies.signed[GITHUB_AUTH_COOKIE].present?
  end

  def auth_related_path?
    # Skip restoration for authentication-related paths
    auth_paths = [
      "/users/sign_in",
      "/users/sign_up",
      "/users/sign_out",
      "/users/password",
      "/users/auth",
      "/github/session_restore"
    ]

    auth_paths.any? { |path| request.path.start_with?(path) }
  end

  # Called when user explicitly logs out - clears the GitHub auth cookie
  def clear_github_auth_cookie
    cookies.delete(GITHUB_AUTH_COOKIE)
    session.delete(RESTORE_ATTEMPTED_KEY)
    session.delete(:github_session_restore)
  end

  def get_like_request?
    request.get? || request.head?
  end
end
