# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data,
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://googleads.g.doubleclick.net"
    policy.object_src  :none

    # Google Tag Manager domains
    gtm_domains = [
      "https://www.googletagmanager.com",
      "https://www.google-analytics.com",
      "https://tagmanager.google.com"
    ]

    # Script policy with comprehensive inline support
    # Note: 'strict-dynamic' is NOT used because:
    # 1. It disables host-based allowlisting (would break Cloudflare Turnstile, GTM, etc.)
    # 2. It requires ALL external scripts to have nonces (not possible with third-party gems)
    # 3. Turbo/Hotwire work perfectly without it
    if Rails.env.development?
      # More permissive for development
      policy.script_src :self, :https, "https://challenges.cloudflare.com", "'unsafe-inline'", *gtm_domains
    else
      # Production policy: allow inline scripts for Turbo compatibility
      policy.script_src :self, :https, "https://challenges.cloudflare.com",
                        :unsafe_inline, *gtm_domains
    end

    # Style policy with unsafe-inline for Turbo compatibility
    # Note: Hashes should NOT be added here because:
    # 1. When a hash is present, 'unsafe-inline' is ignored by browsers
    # 2. Turbo dynamically applies inline styles that cannot be pre-hashed
    # 3. 'unsafe-inline' is necessary for Turbo Frames/Streams
    if Rails.env.development?
      policy.style_src :self, :https, "https://challenges.cloudflare.com", "'unsafe-inline'"
    else
      policy.style_src :self, :https, "https://challenges.cloudflare.com",
                       :unsafe_inline
    end

    policy.frame_src   :self, "https://challenges.cloudflare.com",
                       "https://www.googletagmanager.com"
    policy.connect_src :self, :https, "https://challenges.cloudflare.com",
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://analytics.google.com",
                       "https://region1.google-analytics.com"
  end

  # Nonce configuration for inline scripts
  # Note: Nonces are added to script-src for defense-in-depth, though 'unsafe-inline' is also present
  # Nonces are NOT used for style-src to ensure 'unsafe-inline' works (required for Turbo)
  config.content_security_policy_nonce_directives = %w[script-src]
end
