# Unified test tasks for RSpec, ESLint, and Playwright

namespace :test do
  desc "Reset test DB (schema:load)"
  task :db_reset do
    ENV["RAILS_ENV"] = "test"
    puts "🧹 Resetting test DB (schema:load)"
    system("bin/rails", "db:schema:load")
    abort("DB reset failed") unless $CHILD_STATUS&.success?
  end
  desc "Run RSpec (Rails env: test)"
  task :rspec do
    ENV["RAILS_ENV"] = "test"
    cmd = [ "bundle", "exec", "rspec" ]

    # Respect coverage toggle
    if ENV["COVERAGE"] == "true"
      puts "📊 Coverage enabled for RSpec"
    end

    # Prefer concise output by default
    cmd += [ "--format", ENV["RSPEC_FORMAT"] || "progress" ]

    # Optional fail-fast via env
    cmd += [ "--fail-fast" ] if ENV["RSPEC_FAIL_FAST"] == "1"

    puts "🧪 Running: #{cmd.join(' ')}"
    system(*cmd)
    abort("RSpec failed") unless $CHILD_STATUS&.success?
  end

  desc "Run ESLint for JavaScript (NODE_ENV=test)"
  task "js:lint" do
    ENV["NODE_ENV"] ||= "test"
    cmd = [ "npm", "run", "lint:js" ]
    puts "⚡ Running: #{cmd.join(' ')}"
    system(*cmd)
    abort("ESLint failed") unless $CHILD_STATUS&.success?
  end

  desc "Run Playwright E2E tests (Rails webServer in test env)"
  task :playwright do
    ENV["NODE_ENV"] ||= "test"
    puts "🎯 E2E coverage: #{ENV["E2E_COVERAGE"] == "1" ? "ON" : "OFF"}"
    puts "🎭 Running: npm run test:e2e"
    system("npm", "run", "test:e2e")
    abort("Playwright failed") unless $CHILD_STATUS&.success?
  end

  desc "Run all tests: ESLint → RSpec → Playwright"
  task :all do
    # Ensure a clean test database before RSpec to avoid cross-framework residue
    Rake::Task["test:db_reset"].invoke
    # Lint first (fast, independent)
    Rake::Task["test:js:lint"].invoke

    # Backend tests next
    Rake::Task["test:rspec"].reenable
    Rake::Task["test:rspec"].invoke

    # E2E last (depends on app server) — opt-in via RUN_E2E=1
    if ENV["RUN_E2E"] == "1"
      Rake::Task["test:playwright"].reenable
      Rake::Task["test:playwright"].invoke
    else
      puts "🎭 Skipping Playwright E2E (set RUN_E2E=1 to enable)"
    end
  end
end

# Completely replace the default Rails test task
Rake::Task[:test].clear if Rake::Task.task_defined?(:test)
task :test do
  puts "🎯 Running unified test suite..."
  Rake::Task["test:all"].invoke
end

namespace :coverage do
  desc "Merge coverage from RSpec and E2E into coverage/combined"
  task :merge do
    require "simplecov"
    require "simplecov-lcov"

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = "coverage/combined/lcov.info"
    end

    SimpleCov.coverage_dir "coverage/combined"
    SimpleCov.command_name "combined"
    SimpleCov.collate Dir["coverage/**/.resultset.json"] do
      add_filter "/spec/"
      add_filter "/config/"
      add_filter "/db/"
      add_filter "/vendor/"
      add_filter "/tmp/"
      add_filter "/bin/"
      add_filter "/log/"
      add_filter "/public/"
      add_filter "/storage/"
      add_filter "/node_modules/"
      enable_coverage :branch
      SimpleCov.formatters = [ SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::LcovFormatter ]
    end
    puts "🧩 Merged coverage written to coverage/combined/"
  end

  desc "Run RSpec + Playwright with coverage and merge reports"
  task :all do
    ENV["COVERAGE"] = "true"
    ENV["RUN_E2E"] = "1"
    ENV["E2E_COVERAGE"] = "1"
    Rake::Task["test:all"].invoke
    Rake::Task["coverage:merge"].invoke
  end
end
