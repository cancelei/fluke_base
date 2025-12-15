'use strict';

const configAckamaBase = require('eslint-config-ackama');
const globals = require('globals');

/** @type {import('eslint').Linter.FlatConfig[]} */
const config = [
  { files: ['**/*.{js,jsx,cjs,mjs}'] },
  { ignores: ['tmp/*', 'app/assets/builds/*', 'public/builds/*'] },
  ...configAckamaBase,
  {
    ignores: [
      'config/webpack/*',
      'babel.config.js',
      'eslint.config.js',
      'playwright.config.js',
      'tailwind.config.js',
      'spec/**'
    ],
    languageOptions: {
      globals: {
        ...globals.browser,
        process: 'readonly',
        TurboBoost: 'readonly'
      }
    },
    rules: {
      // Allow anonymous default exports for Stimulus controllers (common pattern)
      'import/no-anonymous-default-export': 'off',
      // Allow nested ternary in some cases
      'no-nested-ternary': 'warn'
    }
  },
  {
    files: [
      'config/webpack/*',
      'babel.config.js',
      'eslint.config.js',
      'playwright.config.js',
      'tailwind.config.js'
    ],
    languageOptions: {
      sourceType: 'commonjs',
      globals: { ...globals.node }
    },
    rules: {
      'strict': ['error', 'global'],
      'n/global-require': 'off'
    }
  },
  // Playwright test files
  {
    files: ['spec/e2e/**/*.js'],
    languageOptions: {
      globals: {
        ...globals.node,
        document: 'readonly',
        window: 'readonly'
      }
    },
    rules: {
      'no-undef': 'off',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'no-await-in-loop': 'warn'
    }
  }
];

module.exports = config;
