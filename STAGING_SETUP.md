# Staging Environment Setup with Caprover

This guide explains how to set up automatic database seeding for your staging environment using Caprover.

## Environment Variables

In your Caprover staging app, make sure to set the following environment variables:

### Required Variables
```
RAILS_ENV=staging
RAILS_MASTER_KEY=<your-staging-master-key>
DATABASE_URL=postgresql://user:password@host:port/database_name
```

### Optional Variables for Seeding Control
```
# Force seeding even if database has existing data
FORCE_SEED=true

# Skip seeding entirely (overrides RAILS_ENV=staging)
SKIP_SEED=true
```

## How It Works

1. **Automatic Seeding**: When `RAILS_ENV=staging`, the startup script automatically runs `rails db:seed` after migrations
2. **Smart Seeding**: In staging, seeding only runs if:
   - The database is empty (User.count == 0), OR
   - `FORCE_SEED=true` is set
3. **Safe Deployment**: If seeding fails, the application still starts (with a warning)

## Deployment Process

Every time you push to your staging branch and Caprover rebuilds:

1. Docker builds the image
2. Container starts with `bin/start.sh`
3. Script waits for PostgreSQL to be ready
4. Runs `rails db:prepare` (migrations)
5. **NEW**: Runs `rails db:seed` if `RAILS_ENV=staging`
6. Starts the Rails application

## Manual Seeding

If you need to manually seed the staging database:

```bash
# Via Caprover CLI
caprover deploy --caproverUrl https://your-caprover-url --appName your-staging-app

# Or connect to running container and run:
rails db:seed RAILS_ENV=staging

# Force re-seed existing data:
FORCE_SEED=true rails db:seed RAILS_ENV=staging
```

## Seed Data

The staging environment will get the same demo data as development:
- 55 test users with predictable scenarios
- 20+ projects across different stages
- Realistic agreements and time logs
- Test user credentials: any user with password `password123`

### Key Test Users
- `alice.entrepreneur@flukebase.me` - Project owner with multiple agreements
- `bob.mentor@flukebase.me` - Active mentor with heavy time logging
- `carol.cofounder@flukebase.me` - Completed co-founder
- `frank.newbie@flukebase.me` - New user with no agreements

## Troubleshooting

### Seeding Issues
- Check Caprover logs for seeding output
- Verify `RAILS_ENV=staging` is set correctly
- Ensure database connection is working
- Check if `SKIP_SEED=true` is accidentally set

### Force Fresh Seed
Set `FORCE_SEED=true` in Caprover environment variables and redeploy.

### Skip Seeding
Set `SKIP_SEED=true` in Caprover environment variables to prevent seeding.

