source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.4"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# TurboBoost Commands for reactive server interactions
gem "turbo_boost-commands", "~> 0.3"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Tailwind CSS for styling
gem "tailwindcss-rails", "~> 4.0"

# ViewComponent for encapsulated, testable view components
gem "view_component", "~> 3.20"

# Authentication
gem "devise"
gem "httparty"

# Cloudflare Turnstile integration
gem "rails_cloudflare_turnstile"

# Rate limiting and attack protection
gem "rack-attack"

# Payments
gem "pay", "~> 6.8"
gem "stripe", "~> 18.0"

# Calendar integration``
gem "google-api-client", require: "google/apis/calendar_v3"

# GitHub API integration
gem "octokit", "~> 6.1"

# AI Agent integration for milestone AI augmentation
gem "ruby_llm"

# Result types for explicit success/failure handling
gem "dry-monads", "~> 1.6"
# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  gem "pry-byebug"
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "~> 7.1.0", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Load environment variables from .env files
  gem "dotenv-rails"

  # Testing framework
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "pundit-matchers"

  # Code coverage
  gem "simplecov", require: false
  gem "simplecov-html", require: false
  gem "simplecov-lcov", require: false
end
gem "faker"

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # ERB linting
  gem "erb_lint", require: false

  # Database schema analysis and optimization
  gem "active_record_doctor"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  # Enable assert_template and render_template matchers used in view/controller specs
  gem "rails-controller-testing"

  # Test reporting
  gem "rspec_junit_formatter"
end

# cssbundling-rails removed - tailwindcss-rails v4 handles CSS natively

gem "kaminari", "~> 1.2"

gem "pundit"

gem "letter_avatar"

gem "faraday-retry", "~> 2.3"

# Materialized views for performance
gem "scenic", "~> 1.8"
