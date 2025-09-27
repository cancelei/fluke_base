# Local overrides to make tests faster and avoid re-installing front-end deps

# Avoid cssbundling-rails forcing `bun install` during test runs via test:prepare
Rake.application.load_rakefile if Rake::Task.tasks.empty?

begin
  if Rake::Task.task_defined?("test:prepare")
    Rake::Task["test:prepare"].clear
  end

  namespace :test do
    desc "Minimal test preparation (DB only)"
    task :prepare do
      if Rake::Task.task_defined?("db:prepare")
        Rake::Task["db:prepare"].invoke
      end
    end
  end
rescue => e
  warn "[test_overrides] Could not override test:prepare: #{e.message}"
end
