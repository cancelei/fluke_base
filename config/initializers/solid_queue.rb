# Configure database connection
Rails.application.config.solid_queue.connects_to = { database: { writing: :primary } }

# Configure mailers queue
Rails.application.config.action_mailer.deliver_later_queue_name = :mailers

# Configure logging
Rails.application.config.solid_queue.logger = ActiveSupport::Logger.new($stdout)
Rails.application.config.solid_queue.logger.level = Logger::DEBUG

# Enable verbose logging for development
if Rails.env.development?
  Rails.application.config.solid_queue.logger.formatter = ::Logger::Formatter.new
  ActiveJob::Base.logger = ActiveSupport::Logger.new($stdout)
  ActiveJob::Base.logger.level = Logger::DEBUG
end
