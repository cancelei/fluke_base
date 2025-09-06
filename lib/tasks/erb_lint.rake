namespace :erb_lint do
  desc "Run ERB Lint on all ERB files"
  task :run do
    puts "Running ERB Lint on all ERB files..."
    system("bundle exec erb_lint --lint-all")
  end

  desc "Run ERB Lint and attempt to autocorrect issues"
  task :autocorrect do
    puts "Running ERB Lint with autocorrect on all ERB files..."
    system("bundle exec erb_lint --lint-all --autocorrect")
  end
end

desc "Alias for erb_lint:run"
task erb_lint: "erb_lint:run"
