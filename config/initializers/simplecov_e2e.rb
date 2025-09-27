# Enable backend coverage when the Rails test server is started for E2E
if ENV["E2E_COVERAGE"].to_s == "1" && Rails.env.test?
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/e2e/lcov.info"
  end

  SimpleCov.command_name "playwright"
  SimpleCov.coverage_dir "coverage/e2e"

  SimpleCov.start "rails" do
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
  end

  puts "📊 E2E backend coverage enabled (SimpleCov)"
end
