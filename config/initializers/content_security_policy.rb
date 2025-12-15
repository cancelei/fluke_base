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
    if Rails.env.development?
      # More permissive for development
      policy.script_src :self, :https, "https://challenges.cloudflare.com", "'unsafe-inline'", "'unsafe-eval'", *gtm_domains
    else
      # Production policy with specific hashes and unsafe-hashes for Turbo
      policy.script_src :self, :https, "https://challenges.cloudflare.com",
                        "'unsafe-hashes'", "'unsafe-inline'",
                        "'sha256-rC8O/z7r/5hFyyAKirUgp0VYdiNfFcPXbRRyUMwtXbE='",
                        "'sha256-ALaDkBo93Qax4JosMrWAFtKE7+rUENfP37WzspJnRXU='",
                        *gtm_domains
    end

    # Style policy with unsafe-hashes for Turbo compatibility
    if Rails.env.development?
      policy.style_src :self, :https, "https://challenges.cloudflare.com", "'unsafe-inline'"
    else
      policy.style_src :self, :https, "https://challenges.cloudflare.com",
                       "'unsafe-hashes'", "'unsafe-inline'",
                       "'sha256-IuYlf9OtyuVBrT3e+V0GJ9PQfQF97T7UBUwlHE5brNQ='"
    end

    policy.frame_src   :self, "https://challenges.cloudflare.com",
                       "https://www.googletagmanager.com"
    policy.connect_src :self, :https, "https://challenges.cloudflare.com",
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://analytics.google.com",
                       "https://region1.google-analytics.com"
  end

  # Improved nonce generator for Turbo compatibility
  config.content_security_policy_nonce_generator = ->(request) do
    # Reuse the same CSP nonce for Turbo requests to avoid violations
    if request.env["HTTP_TURBO_REFERRER"].present? && request.session[:csp_nonce].present?
      request.session[:csp_nonce]
    else
      request.session[:csp_nonce] = SecureRandom.base64(16)
    end
  end

  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
