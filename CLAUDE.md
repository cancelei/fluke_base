# Claude Code Configuration

## Testing Commands
- `rails server` - Start development server
- `rails console` - Start Rails console
- `rails test` - Run test suite
- `bundle exec rspec` - Run RSpec tests (if available)

## Testing Endpoints (No Authentication Required)

Test the Turbo implementations using these endpoints:
- `http://localhost:3000/test/turbo` - Turbo fixes summary
- `http://localhost:3000/test/agreements` - Agreements Turbo features test
- `http://localhost:3000/up` - Rails health check

These endpoints work without authentication and confirm all Turbo implementations are working.

## Database Setup Commands
- `rails db:create` - Create database
- `rails db:migrate` - Run migrations
- `rails db:seed` - Seed initial data
- `rails db:reset` - Reset database completely

## Turbo Testing Notes
- All Turbo implementations have been reviewed and fixed
- Frame structure corrected in agreements/show.html.erb
- Flash messaging properly configured for Turbo Streams
- Controller responses include proper frame awareness
- JavaScript moved to Stimulus controllers