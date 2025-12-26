# frozen_string_literal: true

# Session store configuration
#
# Configure session cookies for proper operation behind Cloudflare proxy.
# This is required because:
# 1. Cloudflare terminates SSL, so Rails needs to know the original protocol
# 2. Session cookies must be secure in production to prevent CSRF attacks
# 3. SameSite=Lax allows the session cookie to be sent on top-level navigations
#
# The CSRF token is stored in the session, so if session cookies aren't
# properly configured, CSRF validation will fail on form submissions.

Rails.application.config.session_store :cookie_store,
  key: "_fluke_base_session",
  same_site: :lax,
  secure: Rails.env.production?
