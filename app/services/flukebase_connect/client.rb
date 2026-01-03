# frozen_string_literal: true

module FlukebaseConnect
  class Client
    include HTTParty

    # Default to localhost if not configured, derived from WebSocket URL if possible
    base_uri ENV.fetch("FLUKEBASE_API_URL") {
      ws_url = ENV.fetch("FLUKEBASE_WS_URL", "ws://localhost:8766")
      ws_url.gsub("ws://", "http://").gsub("wss://", "https://")
    }

    read_timeout 5
    open_timeout 2

    class ConnectionError < StandardError; end

    def self.get_sandboxes
      response = get("/api/v1/sandboxes")

      if response.success?
        response.parsed_response["sandboxes"] || []
      else
        Rails.logger.error "[FlukebaseConnect] Failed to fetch sandboxes: #{response.code} #{response.message}"
        []
      end
    rescue StandardError => e
      Rails.logger.error "[FlukebaseConnect] Connection error: #{e.message}"
      []
    end

    def self.get_logs(limit: 100, filter: nil)
      options = { query: { limit: } }

      if filter.present?
        # Flatten filter params for query string if needed, or send as JSON body if POST
        # Assuming GET with query params for now
        options[:query].merge!(filter)
      end

      response = get("/api/v1/logs", options)

      if response.success?
        response.parsed_response["logs"] || []
      else
        Rails.logger.error "[FlukebaseConnect] Failed to fetch logs: #{response.code} #{response.message}"
        []
      end
    rescue StandardError => e
      Rails.logger.error "[FlukebaseConnect] Connection error: #{e.message}"
      []
    end
  end
end
