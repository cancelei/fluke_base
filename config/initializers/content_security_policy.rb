# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data  # Allow data: URIs for SVG images
    policy.object_src  :none

    # Script policy with comprehensive inline support
    if Rails.env.development?
      # More permissive for development
      policy.script_src :self, :https, "https://challenges.cloudflare.com", "'unsafe-inline'", "'unsafe-eval'"
    else
      # Production policy with specific hashes and unsafe-hashes for Turbo
      policy.script_src :self, :https, "https://challenges.cloudflare.com",
                        "'unsafe-hashes'", "'unsafe-inline'",
                        "'sha256-rC8O/z7r/5hFyyAKirUgp0VYdiNfFcPXbRRyUMwtXbE='",
                        "'sha256-ALaDkBo93Qax4JosMrWAFtKE7+rUENfP37WzspJnRXU='"
    end

    # Style policy with unsafe-hashes for Turbo compatibility
    if Rails.env.development?
      policy.style_src :self, :https, "https://challenges.cloudflare.com", "'unsafe-inline'"
    else
      policy.style_src :self, :https, "https://challenges.cloudflare.com",
                       "'unsafe-hashes'", "'unsafe-inline'",
                       "'sha256-IuYlf9OtyuVBrT3e+V0GJ9PQfQF97T7UBUwlHE5brNQ='"
    end

    policy.frame_src   :self, "https://challenges.cloudflare.com"
    policy.connect_src :self, :https, "https://challenges.cloudflare.com"
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
