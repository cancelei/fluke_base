# Local Setup Guide

**Last Updated**: 2025-12-13
**Document Type**: Quick Start
**Audience**: Developers

Get your FlukeBase development environment up and running in under 10 minutes.

---

## For AI Agents

### Decision Tree: Setup Issues?

```
Did setup fail?
│
├─ asdf/Ruby install error?
│  ├─ asdf not installed? → Install asdf (asdf-vm.com) ✅
│  ├─ Ruby build fails? → Install build dependencies ✅
│  └─ Node build fails? → Check asdf nodejs plugin ✅
│
├─ Database error?
│  ├─ Multi-database config? → Check config/database.yml ✅
│  ├─ Primary DB fails? → Start PostgreSQL, check credentials ✅
│  ├─ Cache/Queue/Cable DB? → Run db:prepare (auto-creates) ✅
│  └─ Migration fails? → Check Rails version (8.0.4) ✅
│
├─ Server won't start?
│  ├─ Port 3000 taken? → Use rails s -p 3001 ✅
│  ├─ Tailwind compile error? → Run npm install ✅
│  └─ Kamal config error? → Check .env for deployment vars ✅
│
└─ Tests failing?
   ├─ Database not created? → RAILS_ENV=test rails db:prepare ✅
   ├─ Fixtures error? → Check test/fixtures/*.yml ✅
   └─ RSpec vs Minitest? → Project uses RSpec ✅
```

### Anti-Patterns

❌ DO NOT skip asdf installation (Ruby 3.4.4 + Node 24.8.0 required)
❌ DO NOT use Ruby < 3.4.4 (Rails 8.0.4 dependency)
❌ DO NOT manually create cache/queue/cable databases (auto-created)
❌ DO NOT skip multi-database setup (4 databases required)
❌ DO NOT commit `.env` or `config/master.key`
✅ DO use asdf for version management
✅ DO run `db:prepare` (handles all 4 databases)
✅ DO use `bin/dev` for full stack
✅ DO check test endpoints after setup

---

## Prerequisites

### Required Software

| Software | Version | Purpose | Managed By |
|----------|---------|---------|------------|
| **Ruby** | 3.4.4 | Application runtime | asdf |
| **Node.js** | 24.8.0 | TailwindCSS, assets | asdf |
| **PostgreSQL** | 16+ | Multi-database setup | System |
| **Git** | Latest | Version control | System |
| **asdf** | Latest | Version manager | System |

### Why asdf?

FlukeBase uses **asdf** for consistent Ruby and Node versions across development, staging, and production environments.

**Benefits**:
- ✅ Automatic version switching (reads `.tool-versions`)
- ✅ Single tool for multiple runtimes
- ✅ Per-project version isolation
- ✅ Production parity

---

## Installation Steps

### 1. Install asdf

**macOS**:
```bash
# Install via Homebrew
brew install asdf

# Add to shell (bash)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.bash_profile

# Add to shell (zsh)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc

# Reload shell
source ~/.zshrc  # or ~/.bash_profile
```

**Ubuntu/Debian**:
```bash
# Install dependencies
sudo apt install curl git

# Clone asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

# Add to shell
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

**Verify Installation**:
```bash
asdf --version
# Should show: v0.14.0 or newer
```

---

### 2. Install Ruby via asdf

```bash
# Add Ruby plugin
asdf plugin add ruby

# Install build dependencies (macOS)
brew install openssl@3 readline libyaml gmp

# Install build dependencies (Ubuntu)
sudo apt-get install autoconf bison build-essential libssl-dev \
  libyaml-dev libreadline-dev zlib1g-dev libncurses5-dev \
  libffi-dev libgdbm-dev

# Install Ruby 3.4.4
asdf install ruby 3.4.4

# Set as global default (optional)
asdf global ruby 3.4.4

# Verify installation
ruby -v
# Should show: ruby 3.4.4
```

---

### 3. Install Node.js via asdf

```bash
# Add Node plugin
asdf plugin add nodejs

# Install Node 24.8.0
asdf install nodejs 24.8.0

# Set as global default (optional)
asdf global nodejs 24.8.0

# Verify installation
node -v
# Should show: v24.8.0

npm -v
# Should show npm version
```

---

### 4. Install PostgreSQL

**macOS (Homebrew)**:
```bash
brew install postgresql@16
brew services start postgresql@16

# Add to PATH
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Verify
psql --version  # Should show PostgreSQL 16.x
```

**Ubuntu/Debian**:
```bash
# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Install PostgreSQL 16
sudo apt update
sudo apt install postgresql-16 postgresql-contrib-16 libpq-dev

# Start service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Create Database User** (if needed):
```bash
# Create user matching your system username
sudo -u postgres createuser -s $(whoami)

# Or create specific user
sudo -u postgres createuser -s -P fluke_base_user
# Enter password when prompted
```

**Verify Connection**:
```bash
psql -U postgres -c "SELECT version();"
# Should show PostgreSQL 16.x
```

---

### 5. Clone Repository

```bash
git clone <repository-url>
cd fluke_base

# Verify asdf auto-detects versions
asdf current
# Should show:
# ruby    3.4.4    (set by /path/to/fluke_base/.tool-versions)
# nodejs  24.8.0   (set by /path/to/fluke_base/.tool-versions)
```

---

### 6. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install Node packages (for TailwindCSS)
npm install
```

**Troubleshooting**:
- **pg gem fails**: Install PostgreSQL dev headers
  ```bash
  # macOS
  brew install postgresql@16

  # Ubuntu
  sudo apt install libpq-dev
  ```

- **Bundle permission error**: Don't use sudo
  ```bash
  # Wrong ❌
  sudo bundle install

  # Right ✅
  bundle install
  ```

---

### 7. Environment Configuration

FlukeBase uses environment variables for configuration:

```bash
# Copy example (if exists)
cp .env.example .env 2>/dev/null || touch .env

# Edit environment file
nano .env
```

**Minimal Configuration** (development):
```bash
# .env

# Database (optional - defaults work for local PostgreSQL)
DATABASE_URL=postgresql://localhost/fluke_base_development

# Test database
DATABASE_URL_TEST=postgresql://localhost/fluke_base_test

# Rails
RAILS_ENV=development
RAILS_MASTER_KEY=<from config/master.key or ask team>

# Optional: Stripe (for payment features)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# Optional: GitHub (for commit tracking)
GITHUB_TOKEN=ghp_...

# Optional: Google Calendar (for meetings)
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
```

**Getting Credentials**:

1. **Rails Master Key**:
   ```bash
   # Check if exists
   cat config/master.key

   # If missing, ask team or generate new
   EDITOR=nano rails credentials:edit
   # Save and exit (creates config/master.key)
   ```

2. **Stripe Keys** (optional):
   - Sign up at [stripe.com](https://stripe.com)
   - Dashboard → Developers → API keys
   - Use "Test mode" for development

3. **GitHub Token** (optional):
   - GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token (classic)
   - Scopes: `repo` (full repository access)

---

### 8. Multi-Database Setup

FlukeBase uses Rails 8.0's multi-database architecture:

```bash
# Create all 4 databases, run migrations, load schema
rails db:prepare

# This creates:
# - fluke_base_development (primary)
# - fluke_base_development_cache (Solid Cache)
# - fluke_base_development_queue (Solid Queue)
# - fluke_base_development_cable (Solid Cable)
```

**Verify Databases**:
```bash
# List databases
psql -U postgres -l | grep fluke_base

# Should show:
# fluke_base_development
# fluke_base_development_cache
# fluke_base_development_queue
# fluke_base_development_cable
```

**Load Sample Data** (optional):
```bash
rails db:seed

# Creates:
# - Sample users (entrepreneurs, mentors)
# - Sample projects
# - Sample agreements
# - Milestones
```

**Manual Database Setup** (if `db:prepare` fails):
```bash
# Create databases
rails db:create

# Load schema (faster than migrations for new setup)
rails db:schema:load

# Or run migrations
rails db:migrate

# Seed data
rails db:seed
```

---

### 9. Start Development Server

**Full Stack (Recommended)**:
```bash
# Start all services via Procfile.dev
bin/dev

# Services started:
# - Rails server (port 3000)
# - TailwindCSS compiler (watch mode)
# - Solid Queue background jobs (optional)
```

**Individual Services**:
```bash
# Terminal 1: Rails server
rails server

# Terminal 2: TailwindCSS
rails tailwindcss:watch

# Terminal 3: Background jobs (if needed)
rails solid_queue:start
```

**Verify Installation**:
```bash
# Visit in browser
open http://localhost:3000

# Health check
curl http://localhost:3000/up
# Should return status code 200
```

---

## Verification Checklist

### ✅ Test Endpoints (No Authentication Required)

FlukeBase provides test endpoints for development:

```bash
# 1. Turbo implementation verification
open http://localhost:3000/test/turbo
# Should show: Turbo features checklist

# 2. Agreement workflows testing
open http://localhost:3000/test/agreements
# Should show: Agreement feature tests

# 3. Health check
curl http://localhost:3000/up
# Should return: Status code 200
```

### ✅ Create Account
1. Visit `http://localhost:3000`
2. Click "Sign Up"
3. Fill registration form
4. Should redirect to dashboard
5. No onboarding flow (unified user experience)

### ✅ Create Project
1. Dashboard → "New Project"
2. Fill project details
3. Should show project page

### ✅ Database Connection
```bash
rails console

# In console:
User.count        # Should return number (0+ depending on seed)
Project.count     # Should return number of projects
Agreement.count   # Should return number of agreements
exit
```

### ✅ Multi-Database Verification
```bash
rails console

# Check each database connection
ActiveRecord::Base.connected?                           # Primary
ActiveRecord::Base.connected_to(role: :writing, shard: :cache) { true }
ActiveRecord::Base.connected_to(role: :writing, shard: :queue) { true }
ActiveRecord::Base.connected_to(role: :writing, shard: :cable) { true }
```

### ✅ Tests Pass
```bash
# Run essential tests (models + helpers)
./bin/test

# Should show:
# - Green dots (passing tests)
# - Test summary (X tests, 0 failures, 0 errors)

# Run specific test types
./bin/test --type unit         # Models, services, helpers
./bin/test --type integration  # Controllers
./bin/test --type system       # Browser tests
```

---

## Common Issues & Solutions

### Issue: asdf command not found

**Symptoms**:
```bash
asdf: command not found
```

**Solution**:
```bash
# Ensure asdf is in shell config
# For zsh
echo '. /opt/homebrew/opt/asdf/libexec/asdf.sh' >> ~/.zshrc
source ~/.zshrc

# For bash
echo '. /opt/homebrew/opt/asdf/libexec/asdf.sh' >> ~/.bash_profile
source ~/.bash_profile

# Verify
asdf --version
```

---

### Issue: Ruby version not automatically detected

**Symptoms**: Wrong Ruby version used despite `.tool-versions`

**Solution**:
```bash
# Ensure in project directory
cd /path/to/fluke_base

# Check what asdf sees
asdf current

# If wrong, manually set local version
asdf local ruby 3.4.4
asdf local nodejs 24.8.0

# Verify .tool-versions created
cat .tool-versions
```

---

### Issue: Multi-database migration errors

**Symptoms**:
```
ActiveRecord::StatementInvalid: PG::UndefinedTable
```

**Solution**:
```bash
# Drop and recreate all databases
rails db:drop
rails db:create
rails db:prepare

# Or reset completely (DESTROYS DATA)
rails db:reset
```

---

### Issue: TailwindCSS styles not loading

**Symptoms**: Page loads but no styles

**Solution**:
```bash
# Rebuild CSS
rails tailwindcss:build

# Start watch mode
rails tailwindcss:watch

# Or use bin/dev (includes Tailwind watch)
bin/dev
```

---

### Issue: Solid Queue not processing jobs

**Symptoms**: Background jobs stuck

**Solution**:
```bash
# Check queue database exists
rails dbconsole -d queue
# Should connect to queue database

# Start queue worker
rails solid_queue:start

# Or use bin/dev
```

---

### Issue: Test database not created

**Symptoms**: Tests fail with database connection error

**Solution**:
```bash
# Create test databases
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:prepare

# Verify
RAILS_ENV=test rails db:version
```

---

### Issue: Port 3000 already in use

**Symptoms**:
```
Address already in use - bind(2) for 127.0.0.1:3000
```

**Solution**:
```bash
# Find process
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
rails server -p 3001
```

---

## Development Workflow

### Daily Development

```bash
# 1. Pull latest changes
git pull origin main

# 2. Update dependencies
bundle install
npm install

# 3. Migrate all databases
rails db:migrate

# 4. Start development
bin/dev
```

### Running Tests

```bash
# Essential tests (models + helpers)
./bin/test

# All tests with coverage
./bin/test --coverage
open coverage/index.html

# Specific test type
./bin/test --type unit
./bin/test --type integration
./bin/test --type system

# Full CI pipeline locally
npm run ci
```

### Code Quality

```bash
# Run all linters
./bin/lint

# Auto-fix issues
./bin/lint --fix

# Individual linters
bundle exec rubocop        # Ruby style
bundle exec brakeman       # Security
bundle exec erb_lint       # ERB templates
npm run lint:js            # JavaScript
```

### Console Access

```bash
# Development console
rails console

# Access specific database
rails dbconsole              # Primary
rails dbconsole -d cache     # Cache DB
rails dbconsole -d queue     # Queue DB
rails dbconsole -d cable     # Cable DB
```

### Database Management

```bash
# Check migration status
rails db:migrate:status

# Rollback last migration
rails db:rollback

# Reset database (DESTROYS DATA)
rails db:reset

# Seed data
rails db:seed
```

---

## Advanced Setup

### Using Overmind (Alternative to bin/dev)

Overmind provides better process management than Foreman:

```bash
# Install Overmind
brew install overmind  # macOS
# or download from github.com/DarthSim/overmind

# Start with Overmind
overmind start

# Benefits:
# - Better terminal output
# - Easier process restart (overmind restart web)
# - Connection to individual processes (overmind connect web)
```

### Docker Development

```bash
# Build image
docker-compose build

# Start services
docker-compose up

# Run commands in container
docker-compose run web rails db:migrate
docker-compose run web rails console
```

---

## Next Steps

After successful setup:

1. **[Create Your First Project](first-project.md)** - Learn project creation
2. **[Create Your First Agreement](first-agreement.md)** - Set up mentorship agreement
3. **[Testing Quick Start](testing-quick-start.md)** - Run test suite
4. **[Development Workflow](../guides/development/development-workflow.md)** - Daily development

---

## Related Documentation

- [Main README](../../README.md) - Project overview
- [Multi-Database Architecture](../guides/architecture/multi-database-architecture.md) - Database setup details
- [Testing Strategy](../guides/testing/testing-strategy.md) - Testing approach
- [Kamal Deployment](../guides/development/kamal-deployment.md) - Production deployment

---

## For AI Agents: Quick Reference

### Files to Check
- **README**: `/README.md` (setup overview)
- **Tool Versions**: `/.tool-versions` (Ruby 3.4.4, Node 24.8.0)
- **Gemfile**: `/Gemfile` (dependencies)
- **Database**: `/config/database.yml` (multi-DB config)
- **Procfile**: `/Procfile.dev` (dev services)

### Common Commands
```bash
# Setup
asdf install
bundle install && npm install
rails db:prepare
rails db:seed

# Development
bin/dev                      # Start all services
rails console                # REPL
./bin/test                  # Run tests
./bin/lint                  # Run linters

# Database (multi-DB aware)
rails db:migrate            # All databases
rails db:reset              # Reset (dev only)
rails dbconsole -d queue    # Access queue DB
```

### Version Check
```bash
asdf current                # Should show Ruby 3.4.4, Node 24.8.0
ruby -v                     # 3.4.4
node -v                     # 24.8.0
psql --version             # PostgreSQL 16+
```

### Multi-Database Quick Check
```bash
# In rails console
ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).map(&:name)
# Should return: ["primary", "cache", "queue", "cable"]
```
