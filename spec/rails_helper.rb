# This file is copied to spec/ when you run 'rails generate rspec:install'
# Set test environment before any Rails loading
ENV['RAILS_ENV'] = 'test'
require 'support/coverage'
require 'spec_helper'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
require 'shoulda-matchers'
require 'rails-controller-testing'
require 'view_component/test_helpers'
require 'capybara/rspec'
require 'pundit/rspec'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Ensure routes are loaded for all tests - force clear and reload
Rails.application.routes.clear!
Rails.application.reload_routes!

RSpec.configure do |config|
  # Configure host authorization for tests
  config.before(:each, type: :request) do
    # Ensure routes are loaded for each request test
    Rails.application.routes.clear!
    Rails.application.reload_routes!
    host! "localhost"
  end

  config.before(:each, type: :controller) do
    # Ensure routes are loaded for each controller test
    Rails.application.routes.clear!
    Rails.application.reload_routes!
  end

  config.before(:each, type: :system) do
    host! "localhost"
  end

  # Conditionally skip JS-enabled system specs when Chrome/Chromium is unavailable
  chrome_available = begin
    ENV['FORCE_SYSTEM_JS'] == '1' || %w[google-chrome chrome chromium chromium-browser].any? do |cmd|
      system("which #{cmd} >/dev/null 2>&1")
    end
  rescue StandardError
    false
  end

  selenium_enabled = ENV['USE_SELENIUM'] == '1' && chrome_available

  # Exclude JS-enabled system specs entirely unless explicitly enabled
  config.filter_run_excluding js: true, type: :system unless selenium_enabled

  config.before(:each, type: :system, js: true) do |example|
    unless selenium_enabled
      skip "Selenium not enabled; set USE_SELENIUM=1 to run JS system specs"
    end
  end
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/7-1/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Configure FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Configure ViewComponent test helpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  # Configure Shoulda Matchers
  config.include Shoulda::Matchers::ActiveModel, type: :model
  config.include Shoulda::Matchers::ActiveRecord, type: :model

  # Configure Devise test helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Include Rails route helpers for request specs
  config.include Rails.application.routes.url_helpers, type: :request

  # Configure Warden test helpers for system tests
  config.include Warden::Test::Helpers, type: :system

  # Clean up Warden after each test
  config.after(:each, type: :system) do
    Warden.test_reset!
  end

  # Configure Capybara for system tests
  config.before(:each, type: :system) do |example|
    if example.metadata[:js] && selenium_enabled
      driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ] do |options|
        options.add_argument('--headless') if ENV['HEADLESS']
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        options.add_argument('--disable-web-security')
        options.add_argument('--disable-features=VizDisplayCompositor')
      end
    else
      driven_by :rack_test
      # For rack_test, we need to set the app host
      Capybara.app_host = "http://localhost"
    end
  end

  # Configure database cleaning for system tests
  config.before(:each, type: :system) do
    config.use_transactional_fixtures = false
  end

  config.after(:each, type: :system) do
    config.use_transactional_fixtures = true
  end
end

# Enable template assertions for controller and view specs
Rails::Controller::Testing.install if defined?(Rails::Controller::Testing)
RSpec.configure do |config|
  config.include Rails::Controller::Testing::TemplateAssertions, type: :view
  config.include Rails::Controller::Testing::TemplateAssertions, type: :controller
end

# Ensure view filename annotations are disabled for view specs comparisons
begin
  ActionView::Base.annotate_rendered_view_with_filenames = false
rescue StandardError
  # noop
end
# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
