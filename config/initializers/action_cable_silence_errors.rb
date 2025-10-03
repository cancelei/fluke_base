# Silence harmless ActionCable unsubscribe race condition errors
# This happens when a page unloads and tries to unsubscribe twice from the same channel
# See: https://github.com/hotwired/turbo-rails/issues/131

module ActionCable
  module Connection
    class Subscriptions
      # Override to gracefully handle duplicate unsubscribe attempts
      def remove(data)
        logger.info "Unsubscribing from channel: #{data['identifier']}"
        find(data).unsubscribe_from_channel
      rescue RuntimeError => e
        # Silently ignore "Unable to find subscription" errors during unsubscribe
        # This happens when Turbo tries to unsubscribe twice (race condition)
        if e.message.include?("Unable to find subscription")
          logger.debug "Attempted to unsubscribe from already removed subscription: #{data['identifier']}"
        else
          raise
        end
      end
    end
  end
end
