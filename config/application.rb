require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FlukeBase
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Security headers
    config.action_dispatch.default_headers["Permissions-Policy"] = "interest-cohort=()"
    config.action_dispatch.default_headers["X-Frame-Options"] = "DENY"

    # Rate limiting and attack protection
    config.middleware.use Rack::Attack

    # ViewComponent configuration
    config.view_component.generate.sidecar = false
    config.view_component.generate.stimulus_controller = false
  end
end
