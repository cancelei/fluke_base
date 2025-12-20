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
    # Enhanced coverage thresholds
    minimum_coverage 75 # Increased from 20 to encourage better coverage
    minimum_coverage_by_file 50 # Set minimum per-file coverage

    # Directories to exclude from coverage
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/db/'
    add_filter '/vendor/'
    add_filter '/tmp/'
    add_filter '/bin/'
    add_filter '/log/'
    add_filter '/public/'
    add_filter '/storage/'
    add_filter '/node_modules/'
    add_filter 'app/channels/application_cable'

    # Enhanced grouping for better reporting
    add_group 'Controllers', 'app/controllers'
    add_group 'Models', 'app/models'
    add_group 'Services', 'app/services'
    add_group 'Forms', 'app/forms'
    add_group 'Queries', 'app/queries'
    add_group 'Presenters', 'app/presenters'
    add_group 'Policies', 'app/policies'
    add_group 'Jobs', 'app/jobs'
    add_group 'Helpers', 'app/helpers'
    add_group 'Views', 'app/views'
    add_group 'Mailers', 'app/mailers'
    add_group 'Validators', 'app/validators'
    add_group 'Libraries', 'lib'
    add_group 'JavaScript', 'app/javascript'

    # Exclude base/abstract classes and generated files
    add_filter 'app/controllers/application_controller.rb'
    add_filter 'app/models/application_record.rb'
    add_filter 'app/jobs/application_job.rb'
    add_filter 'app/mailers/application_mailer.rb'
    add_filter 'app/forms/application_form.rb'
    add_filter 'app/channels/application_cable/'

    # Track branches for more comprehensive coverage
    enable_coverage :branch

    # Custom coverage criteria
    coverage_criteria = {
      primary: 90,    # Models, Controllers, Services
      secondary: 80,  # Helpers, Presenters, Policies
      tertiary: 70    # Views, Jobs, Mailers
    }

    # Set different coverage requirements by file type
    at_exit do
      result = SimpleCov.result

      # Check coverage by group
      primary_groups = ['Controllers', 'Models', 'Services', 'Forms', 'Queries']
      secondary_groups = ['Helpers', 'Presenters', 'Policies', 'Validators']
      tertiary_groups = ['Views', 'Jobs', 'Mailers']

      primary_files = result.files.select { |f| primary_groups.any? { |g| f.filename.include?(g.downcase) } }
      secondary_files = result.files.select { |f| secondary_groups.any? { |g| f.filename.include?(g.downcase) } }
      tertiary_files = result.files.select { |f| tertiary_groups.any? { |g| f.filename.include?(g.downcase) } }

      if primary_files.any? && primary_files.map(&:covered_percent).sum / primary_files.size < coverage_criteria[:primary]
        puts "\n❌ Primary code coverage below #{coverage_criteria[:primary]}%"
        puts "   Focus on: Controllers, Models, Services, Forms, Queries"
      end

      if secondary_files.any? && secondary_files.map(&:covered_percent).sum / secondary_files.size < coverage_criteria[:secondary]
        puts "\n⚠️  Secondary code coverage below #{coverage_criteria[:secondary]}%"
        puts "   Focus on: Helpers, Presenters, Policies, Validators"
      end

      if result.covered_percent >= 90
        puts "\n🎉 Excellent test coverage: #{result.covered_percent.round(2)}%"
      elsif result.covered_percent >= 75
        puts "\n✅ Good test coverage: #{result.covered_percent.round(2)}%"
      else
        puts "\n⚠️  Test coverage needs improvement: #{result.covered_percent.round(2)}%"
      end
    end
  end

  puts "📊 Code coverage tracking enabled"
end
