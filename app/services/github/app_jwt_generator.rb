# frozen_string_literal: true

module Github
  # Generates a JSON Web Token (JWT) for GitHub App authentication
  #
  # GitHub Apps use JWT to authenticate as the app itself (not as a user)
  # The JWT is used to get installation access tokens
  #
  # Usage:
  #   jwt = Github::AppJwtGenerator.call
  #   # => "eyJhbGciOiJSUzI1NiIs..."
  #
  class AppJwtGenerator < ApplicationService
    ALGORITHM = "RS256"
    TOKEN_EXPIRY_SECONDS = 10 * 60 # 10 minutes (max allowed by GitHub)
    CLOCK_DRIFT_SECONDS = 60 # Account for clock drift between servers

    def call
      payload = build_payload
      private_key = load_private_key

      Success(JWT.encode(payload, private_key, ALGORITHM))
    rescue StandardError => e
      Rails.logger.error "[Github::AppJwtGenerator] Failed to generate JWT: #{e.message}"
      failure_result(:jwt_generation_failed, e.message)
    end

    private

    def build_payload
      now = Time.now.to_i

      {
        iat: now - CLOCK_DRIFT_SECONDS, # Issued 60s ago to account for clock drift
        exp: now + TOKEN_EXPIRY_SECONDS, # Expires in 10 minutes
        iss: app_id
      }
    end

    def load_private_key
      pem = Github::AppConfig.private_key
      raise "GitHub App private key not configured" if pem.blank?

      OpenSSL::PKey::RSA.new(pem)
    end

    def app_id
      id = Github::AppConfig.app_id
      raise "GitHub App ID not configured" if id.blank?

      id
    end
  end
end
