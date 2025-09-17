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

# SolidCache, SolidQueue, and SolidCable tables are in schema - no manual creation needed

# Start the application
exec "$@"
