# syntax=docker/dockerfile:1
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# ----- Build stage -----
FROM base AS build

# Install build-time dependencies including Node.js 20.x and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libyaml-dev pkg-config nodejs yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}/ruby/*/cache" "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git" && \
    bundle exec bootsnap precompile --gemfile

# JS packages
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# App code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Ensure rails script is executable in minimal build contexts
RUN chmod +x ./bin/rails

# Deterministic asset build (Tailwind runs inside assets:precompile)
# - Use dummy secrets/DB to avoid hitting real infra
# - NODE_ENV=production ensures minified/purged CSS at build time
ENV NODE_ENV=production
RUN SECRET_KEY_BASE_DUMMY=1 \
    DATABASE_URL="postgresql://postgres:postgres@localhost:5432/dummy" \
    SKIP_DB_INITIALIZER=true \
    bundle exec rails assets:precompile

# ----- Final stage -----
FROM base

# Copy built artifacts
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Rails will serve compiled assets (or put a CDN/Nginx in front if you prefer)
ENV RAILS_SERVE_STATIC_FILES=1 \
    RAILS_LOG_TO_STDOUT=1

# Create start script before switching users
RUN echo '#!/bin/bash
set -e

# Extract connection details from DATABASE_URL
DB_USER=$(echo $DATABASE_URL | sed -E "s/^postgresql:\\/\\/([^:]+):.*/\\1/")
DB_PASS=$(echo $DATABASE_URL | sed -E "s/^postgresql:\\/\\/[^:]+:([^@]+)@.*/\\1/")
DB_HOST=$(echo $DATABASE_URL | sed -E "s/^postgresql:\\/\\/[^@]+@([^\\/]+)\\/.*/\\1/")
DB_NAME=$(echo $DATABASE_URL | sed -E "s/^postgresql:\\/\\/[^@]+@[^\\/]+\\/(.*)/\\1/")

# Wait for PostgreSQL to be ready
until PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

# Run database migrations
./bin/rails db:prepare

# Start the application
exec "$@"' > /rails/bin/start.sh && \
chmod +x /rails/bin/start.sh

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/start.sh"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
