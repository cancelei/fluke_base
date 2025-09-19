# GEMINI.md

## Project Overview

This is a Ruby on Rails project called FlukeBase. It's a collaborative platform that connects entrepreneurs, mentors, and co-founders. The platform allows users to create projects, manage milestones, track time, and create agreements with other users. It also has a messaging system for communication between users.

The project uses a number of modern technologies, including:

*   **Backend:** Rails 8.0.2
*   **Frontend:** Hotwire (Turbo and Stimulus), Tailwind CSS
*   **Database:** PostgreSQL
*   **Authentication:** Devise
*   **Payments:** Pay and Stripe
*   **Background Jobs:** Solid Queue
*   **Real-time:** Solid Cable
*   **Deployment:** Kamal

## Building and Running

### Requirements

*   Ruby 3.2.1+
*   PostgreSQL 16+
*   Node.js 20+
*   Git

### Development Setup

```bash
# Clone and setup
git clone <repository-url>
cd fluke_base
bundle install
npm install

# Database setup
rails db:create
rails db:migrate
rails db:seed

# Start development server
rails server
```

Visit `http://localhost:3000` to access the application.

### Testing

```bash
# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/models/user_spec.rb
```

## Development Conventions

*   **Code Style:** The project uses RuboCop to enforce a consistent code style. You can run RuboCop with `bundle exec rubocop`.
*   **Testing:** The project uses RSpec for testing. All new features should be accompanied by tests.
*   **Branching:** Create a new branch for each feature. Once the feature is complete, create a pull request to merge it into the `main` branch.
