# frozen_string_literal: true

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ]

  SimpleCov.start 'rails' do
    # Coverage thresholds
    minimum_coverage 80
    minimum_coverage_by_file 70

    # Directories to include in coverage
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/db/'
    add_filter '/vendor/'
    add_filter '/tmp/'
    add_filter '/bin/'
    add_filter '/log/'
    add_filter '/public/'
    add_filter '/storage/'
    add_filter 'app/channels/application_cable'

    # Group coverage results
    add_group 'Controllers', 'app/controllers'
    add_group 'Models', 'app/models'
    add_group 'Helpers', 'app/helpers'
    add_group 'Views', 'app/views'
    add_group 'Jobs', 'app/jobs'
    add_group 'Mailers', 'app/mailers'
    add_group 'Services', 'app/services'
    add_group 'Libraries', 'lib'

    # Exclude certain files from coverage
    add_filter 'app/controllers/application_controller.rb'
    add_filter 'app/models/application_record.rb'
    add_filter 'app/jobs/application_job.rb'
    add_filter 'app/mailers/application_mailer.rb'
  end

  puts "📊 Code coverage tracking enabled"
end
