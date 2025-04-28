# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.2.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage
FROM base AS build

# Install build-time dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}/ruby/*/cache" "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git" && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets with dummy vars to avoid KeyError
RUN SECRET_KEY_BASE_DUMMY=1 \
    FLUKE_BASE_DATABASE_USERNAME=dummy \
    FLUKE_BASE_DATABASE_PASSWORD=dummy\
    SKIP_DB_INITIALIZER=true \
    ./bin/rails assets:precompile 

# Final stage
FROM base

# Copy built artifacts
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
