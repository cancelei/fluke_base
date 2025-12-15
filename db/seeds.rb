# Load environment-specific seeds
# In production: minimal or no seeds (users create their own data)
# In staging: development-style test data for testing
# In development: comprehensive test data with predictable scenarios

# Skip seeding in test environment (tests create their own data)
return if Rails.env.test?

# Route to environment-specific seed files
if Rails.env.production?
  # Production: Only seed if explicitly enabled via SEED_PRODUCTION=true
  if ENV['SEED_PRODUCTION'] == 'true'
    puts "🌱 Loading production seeds..."
    load Rails.root.join('db/seeds/production.rb')
  else
    puts "ℹ️  Skipping production seeds (set SEED_PRODUCTION=true to enable)"
  end
elsif Rails.env.staging?
  # Staging: Auto-seed unless SKIP_SEED=true
  unless ENV['SKIP_SEED'] == 'true'
    puts "🌱 Loading staging seeds (using development seeds for testing)..."
    load Rails.root.join('db/seeds/development.rb')
  else
    puts "⏭️  Skipping staging seeds (SKIP_SEED=true)"
  end
else
  # Development: Always seed with comprehensive test data
  puts "🌱 Loading development seeds..."
  load Rails.root.join('db/seeds/development.rb')
end
