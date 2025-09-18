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

    # Allow inline scripts and styles with nonces, plus unsafe-hashes for Turbo compatibility
    policy.script_src  :self, :https, "https://challenges.cloudflare.com", "'unsafe-hashes'",
                      "'sha256-rC8O/z7r/5hFyyAKirUgp0VYdiNfFcPXbRRyUMwtXbE='",
                      "'sha256-ALaDkBo93Qax4JosMrWAFtKE7+rUENfP37WzspJnRXU='"

    policy.style_src   :self, :https, "https://challenges.cloudflare.com", "'unsafe-hashes'",
                      "'sha256-IuYlf9OtyuVBrT3e+V0GJ9PQfQF97T7UBUwlHE5brNQ='"

    policy.frame_src   :self, "https://challenges.cloudflare.com"
    policy.connect_src :self, :https, "https://challenges.cloudflare.com"

    policy.report_uri "/csp-violation-report-endpoint"
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
