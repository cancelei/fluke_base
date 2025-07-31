# SolidQueue Deployment Fixes

This document outlines the fixes applied to resolve the background worker deployment issues.

## Issues Fixed

### 1. Association Error in GithubService
**Problem**: The `GithubService` was trying to include non-existent associations `:initiator` and `:other_party` on the `Agreement` model.

**Fix**: Updated `app/services/github_service.rb` to use the correct associations:
```ruby
# Before (causing error)
@agreements = project.agreements.active.includes(:initiator, :other_party)
related_users = ([ project.user ] + agreements.map(&:initiator) + agreements.map(&:other_party)).compact.uniq

# After (fixed)
@agreements = project.agreements.active.includes(agreement_participants: :user)
agreement_users = agreements.flat_map { |agreement| agreement.agreement_participants.map(&:user) }
related_users = ([ project.user ] + agreement_users).compact.uniq
```

### 2. Database Configuration Mismatch
**Problem**: Conflicting database configurations between different config files:
- `config/initializers/solid_queue.rb` specified `:primary` database
- `config/environments/production.rb` and `staging.rb` specified `:queue` database

**Fix**: Updated both environment files to use `:primary` database to match the initializer:
```ruby
# Before
config.solid_queue.connects_to = { database: { writing: :queue } }

# After  
config.solid_queue.connects_to = { database: { writing: :primary } }
```

### 3. SolidQueue Auto-Start Configuration  
**Problem**: Background workers weren't starting automatically on deployment.

**Current Setup**: 
- `SOLID_QUEUE_IN_PUMA: true` in `config/deploy.yml`
- Puma plugin configured in `config/puma.rb`: `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]`
- Database configured to use primary database for queue operations

**Additional Reliability Measures**:
- Enabled `JOB_CONCURRENCY: 3` in deployment config
- Created fallback `bin/workers` script for manual worker management if needed

## How It Works Now

1. **In Production**: SolidQueue runs inside Puma processes via the Puma plugin
2. **Database**: Uses the primary database instead of a separate queue database
3. **Job Processing**: 3 concurrent job processes as configured
4. **Error Handling**: Fixed association preloading prevents job failures

## Verification

To verify the fix is working:

1. **Check if workers are running**:
   ```bash
   docker exec <container_id> ps aux | grep solid_queue
   ```

2. **Check job processing**:
   ```bash
   docker exec <container_id> rails runner "puts SolidQueue::Job.count"
   ```

3. **Monitor logs**:
   ```bash
   docker logs <container_id> | grep -i solid
   ```

## Fallback Options

If the Puma plugin approach doesn't work, you can:

1. Use the dedicated job server approach by uncommenting the job section in `config/deploy.yml`:
   ```yaml
   servers:
     web:
       - 192.168.0.1
     job:
       hosts:
         - 192.168.0.1
       cmd: bin/jobs
   ```

2. Or use the new `bin/workers` script for manual worker management.

## Key Takeaways

- Always ensure database configurations are consistent across all config files
- When using `SOLID_QUEUE_IN_PUMA: true`, use the primary database, not a separate queue database
- The SolidQueue Puma plugin is the most cost-effective approach for single-server deployments
- Proper association preloading is crucial for job processing reliability 