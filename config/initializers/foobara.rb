# frozen_string_literal: true

require "foobara/activejob_connector"

# Create the ActiveJob connector instance
FOOBARA_ACTIVEJOB_CONNECTOR = Foobara::CommandConnectors::ActivejobConnector.new(name: :default)

# Connect commands after Rails initialization
Rails.application.config.after_initialize do
  if defined?(Demo::ProcessData)
    FOOBARA_ACTIVEJOB_CONNECTOR.connect(Demo::ProcessData, queue: :default)
  end
end
