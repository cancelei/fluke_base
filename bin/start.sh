#!/bin/bash
set -e

# Extract connection details from DATABASE_URL
DB_USER=$(echo $DATABASE_URL | sed -E "s/^postgresql:\/\/([^:]+):.*/\1/")
DB_PASS=$(echo $DATABASE_URL | sed -E "s/^postgresql:\/\/[^:]+:([^@]+)@.*/\1/")
DB_HOST=$(echo $DATABASE_URL | sed -E "s/^postgresql:\/\/[^@]+@([^\/]+)\/.*/\1/")
DB_NAME=$(echo $DATABASE_URL | sed -E "s/^postgresql:\/\/[^@]+@[^\/]+\/(.*)/\1/")

# Wait for PostgreSQL to be ready
until PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

# Run database migrations
./bin/rails db:prepare

# Create solid_cache_entries table if it doesn't exist
./bin/rails runner "begin; ActiveRecord::Base.connection.execute('CREATE TABLE IF NOT EXISTS solid_cache_entries (key bytea NOT NULL, value bytea NOT NULL, created_at timestamp NOT NULL, key_hash bigint NOT NULL, byte_size integer NOT NULL); CREATE UNIQUE INDEX IF NOT EXISTS index_solid_cache_entries_on_key_hash ON solid_cache_entries (key_hash); CREATE INDEX IF NOT EXISTS index_solid_cache_entries_on_byte_size ON solid_cache_entries (byte_size); CREATE INDEX IF NOT EXISTS index_solid_cache_entries_on_key_hash_and_byte_size ON solid_cache_entries (key_hash, byte_size);'); puts 'Solid cache table created successfully'; rescue => e; puts 'Solid cache table already exists or error: ' + e.message; end" || true

# Start the application
exec "$@"
