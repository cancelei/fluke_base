# Service to verify Cloudflare Turnstile tokens
class TurnstileVerificationService
  include HTTParty

  base_uri "https://challenges.cloudflare.com"

  def initialize(token, remote_ip = nil)
    @token = token
    @remote_ip = remote_ip
  end

  def verify
    return false if @token.blank?

    response = self.class.post("/turnstile/v0/siteverify", {
      body: {
        secret: Rails.application.config.turnstile[:secret_key],
        response: @token,
        remoteip: @remote_ip
      }
    })

    if response.success?
      result = response.parsed_response
      result["success"] == true
    else
      Rails.logger.error "Turnstile verification failed: #{response.code} - #{response.message}"
      false
    end
  rescue => e
    Rails.logger.error "Turnstile verification error: #{e.message}"
    false
  end

  class << self
    def verify(token, remote_ip = nil)
      new(token, remote_ip).verify
    end
  end
end
