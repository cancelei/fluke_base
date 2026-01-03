#!/usr/bin/env node

/**
 * Run Playwright E2E tests against development environment
 * 
 * This script runs the seed user journey tests against the development
 * database with real seed data, instead of the test environment.
 * 
 * Prerequisites:
 * 1. Development server running: `bin/dev` or `rails server`
 * 2. Seeds loaded: `rails db:seed`
 * 
 * Usage:
 *   node spec/e2e/run-dev-tests.js [--headed]
 */

const { spawn } = require('child_process');
const path = require('path');

const args = process.argv.slice(2);
const headed = args.includes('--headed');

console.log('🧪 Running E2E tests against development environment\n');
console.log('Prerequisites:');
console.log('  ✓ Development server should be running on http://localhost:3000');
console.log('  ✓ Seeds should be loaded (rails db:seed)\n');

const playwrightArgs = [
  'playwright',
  'test',
  'spec/e2e/seed_user_journey.spec.js',
  '--config',
  'spec/e2e/playwright-dev.config.js'
];

if (headed) {
  playwrightArgs.push('--headed');
}

const npx = spawn('npx', playwrightArgs, {
  stdio: 'inherit',
  shell: true
});

npx.on('close', (code) => {
  if (code === 0) {
    console.log('\n✅ Development E2E tests passed!');
  } else {
    console.log(`\n❌ Tests failed with code ${code}`);
  }
  process.exit(code);
});
