# frozen_string_literal: true

module Github
  # Centralized configuration for GitHub App settings
  #
  # Reads from environment variables first, falls back to Rails credentials
  # This allows flexible deployment options (ENV for Docker, credentials for development)
  #
  # Usage:
  #   Github::AppConfig.app_id
  #   Github::AppConfig.client_id
  #   Github::AppConfig.private_key
  #
  class AppConfig
    class << self
      def app_id
        ENV.fetch("GITHUB_APP_ID") { credentials(:app_id) }
      end

      def client_id
        ENV.fetch("GITHUB_APP_CLIENT_ID") { credentials(:client_id) }
      end

      def client_secret
        ENV.fetch("GITHUB_APP_CLIENT_SECRET") { credentials(:client_secret) }
      end

      def private_key
        key = ENV["GITHUB_APP_PRIVATE_KEY"].presence ||
              private_key_from_file ||
              credentials(:private_key)

        return nil if key.blank?

        # Handle escaped newlines from environment variables
        key.gsub('\n', "\n")
      end

      def webhook_secret
        ENV.fetch("GITHUB_APP_WEBHOOK_SECRET") { credentials(:webhook_secret) }
      end

      def configured?
        app_id.present? && client_id.present? && client_secret.present?
      end

      def fully_configured?
        configured? && private_key.present?
      end

      private

      def credentials(key)
        Rails.application.credentials.dig(:github_app, key)
      end

      def private_key_from_file
        path = ENV["GITHUB_APP_PRIVATE_KEY_PATH"]
        return nil unless path.present? && File.exist?(path)

        File.read(path)
      end
    end
  end
end
