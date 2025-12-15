# Playwright E2E Test Setup

This directory contains global setup scripts for Playwright end-to-end tests.

## Files

- `global-setup.js` - Runs before all tests to prepare the test environment

## Configuration

The setup script supports the following environment variables:

### Always Enabled
- **Authenticated Session**: Always logs in via `/test_only/login` and saves state to `tmp/playwright/auth.json`

### Optional Features
- `SEED_TEST_DATA=1` - Seed test data via `bundle exec rake e2e:seed_test_data`
- `RAILS_ENV` - Rails environment (default: test)

## Usage

### Standard Test Run
```bash
npm run test:e2e
```

### With Test Data Seeding
```bash
SEED_TEST_DATA=1 npm run test:e2e
```

## Authenticated Tests

All tests can use the saved authentication state by configuring their storage state:

```javascript
test.use({ storageState: 'tmp/playwright/auth.json' });
```

See `spec/e2e/authenticated_home.spec.js` for an example.

## Standardization

This setup pattern is standardized across all projects (guide, fluke_base, feeltrack):
- **Location**: `spec/e2e/setup/` directory
- **ES Modules**: Uses `import/export` syntax
- **Flexible**: Supports both data seeding and auth state via environment variables
- **Consistent**: Same pattern and documentation across all projects
