# Linting Guide

**Last Updated**: 2025-12-20
**Document Type**: Guide
**Audience**: Developers, AI Agents

This guide explains the code quality and linting setup for FlukeBase.

---

## Quick Start

### Run All Linters

```bash
# Check all files (no changes)
./bin/lint

# Auto-fix all issues
./bin/lint --fix
```

### Run Individual Linters

```bash
# RuboCop only
bundle exec rubocop
bundle exec rubocop -A  # Auto-fix

# ESLint only
npm run lint:js
npm run lint:js:fix  # Auto-fix

# All via npm
npm run lint
npm run lint:fix
```

---

## Available Linters

FlukeBase uses six linters for comprehensive code quality:

### 1. RuboCop (Ruby)

**Purpose**: Enforces Ruby style guide and best practices

**Configuration**: `.rubocop.yml`

**Run directly**:
```bash
bundle exec rubocop              # Check only
bundle exec rubocop -A           # Auto-correct
```

**Key rules**:
- Line length: 120 characters
- Method length: 20 lines (excluding migrations, specs, controllers)
- Uses double quotes for strings
- Enforces Rails best practices
- RSpec and FactoryBot conventions

**Plugins**:
- rubocop-capybara
- rubocop-factory_bot
- rubocop-performance
- rubocop-rails
- rubocop-rspec
- rubocop-rspec_rails

### 2. Brakeman (Security)

**Purpose**: Static analysis for security vulnerabilities

**Configuration**: `config/brakeman.ignore` (false positives)

**Run directly**:
```bash
bundle exec brakeman              # Full scan
bundle exec brakeman --quiet      # Minimal output
```

**What it checks**:
- SQL injection vulnerabilities
- Cross-site scripting (XSS)
- Mass assignment issues
- Insecure redirects
- Command injection

### 3. ERB Lint (Templates)

**Purpose**: Lints ERB templates for security and style

**Configuration**: `.erb_lint.yml`

**Run directly**:
```bash
bundle exec erb_lint --lint-all               # Check only
bundle exec erb_lint --lint-all -a            # Auto-fix
```

**Key rules**:
- Enforces ERB safety
- Self-closing tags
- Proper HTML structure

### 4. ESLint (JavaScript)

**Purpose**: Enforces JavaScript style and best practices

**Configuration**: `eslint.config.js`

**Run directly**:
```bash
npm run lint:js          # Check only
npm run lint:js:fix      # Auto-fix
```

**Key rules**:
- Modern ES6+ syntax
- Import/export best practices
- Prettier integration for formatting

### 5. Hadolint (Dockerfile)

**Purpose**: Lints Dockerfile for best practices

**Configuration**: `.hadolint.yaml`

**Run directly**:
```bash
bin/linters/hadolint --config .hadolint.yaml Dockerfile
```

**Key rules**:
- Pin package versions
- Use multi-stage builds
- Minimize layers
- Security best practices

### 6. YAML Lint (YAML Files)

**Purpose**: Validates YAML syntax in config files

**Run directly**:
```bash
npx yaml-lint config/*.yml .github/workflows/*.yml
```

**Key rules**:
- Valid YAML syntax
- Proper indentation
- No duplicate keys

---

## Configuration Files

```
.
├── .rubocop.yml         # RuboCop configuration
├── .erb_lint.yml        # ERB Lint configuration
├── eslint.config.js     # ESLint configuration
├── .hadolint.yaml       # Hadolint configuration
├── config/brakeman.ignore  # Brakeman false positives
└── bin/lint             # Unified lint runner script
```

---

## CI/CD Integration

The unified lint script is designed for CI/CD pipelines:

```bash
# In your CI pipeline
./bin/lint
```

Exit codes:
- `0`: All linters passed
- `1`: One or more linters failed

You can also run via npm:
```bash
npm run ci  # Full CI pipeline (lint + test with coverage)
```

---

## Common Issues and Solutions

### RuboCop: Metrics violations

**Issue**: Methods are too complex or too long

**Solution**:
- Break down large methods into smaller ones
- Extract logic into service objects
- Use concerns for shared behavior
- Some exceptions are configured (controllers, specs, jobs)

### ESLint: Import ordering

**Issue**: Imports are not in the correct order

**Solution**:
```javascript
// External imports first
import { Controller } from '@hotwired/stimulus';

// Internal imports second
import { formatTime } from '../utils/time';
```

### Brakeman: False positives

**Issue**: Brakeman flags code that is actually safe

**Solution**:
Add to `config/brakeman.ignore`:
```json
{
  "ignored_warnings": [
    {
      "fingerprint": "abc123...",
      "note": "Reason why this is safe"
    }
  ]
}
```

### Hadolint: Package version pinning

**Issue**: `DL3008 Pin versions in apt get install`

**Solution**:
```dockerfile
# Bad
RUN apt-get install -y curl

# Good
RUN apt-get install -y curl=7.68.0-1ubuntu2
```

---

## Disabling Rules

### In specific files

**Ruby:**
```ruby
# rubocop:disable Style/Documentation
class MyClass
  # ...
end
# rubocop:enable Style/Documentation
```

**JavaScript:**
```javascript
/* eslint-disable no-console */
console.log('Debug info');
/* eslint-enable no-console */
```

### In configuration

Edit the respective configuration file:
- `.rubocop.yml` for Ruby rules
- `eslint.config.js` for JavaScript rules
- `.hadolint.yaml` for Dockerfile rules

---

## Pre-commit Hooks

Add linting to pre-commit hooks using Lefthook:

```yaml
# lefthook.yml
pre-commit:
  commands:
    lint:
      run: ./bin/lint
```

---

## Auto-fix on Save (Editor Integration)

### VS Code

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "ruby.rubocop.onSave": true,
  "[ruby]": {
    "editor.defaultFormatter": "rubocop"
  }
}
```

---

## Performance Tips

1. **Run only changed files**:
   ```bash
   # RuboCop on changed files
   git diff --name-only --diff-filter=AM | grep '\.rb$' | xargs bundle exec rubocop

   # ESLint on changed files
   git diff --name-only --diff-filter=AM | grep '\.js$' | xargs npm run lint:js --
   ```

2. **Use linter caches**:
   - RuboCop: Uses `tmp/.rubocop_cache/` automatically
   - ESLint: Uses `.eslintcache`

3. **Parallel execution**:
   - bin/lint runs all linters in parallel using threads

---

## Contributing

When contributing to FlukeBase:

1. **Run linters before committing**:
   ```bash
   ./bin/lint --fix
   ```

2. **Address all violations**: Don't commit code with linting errors

3. **Disable rules sparingly**: Only disable rules with good reason and add a comment explaining why

4. **Update configs carefully**: Discuss significant config changes with the team

---

## Resources

- [RuboCop Documentation](https://docs.rubocop.org/)
- [ESLint Documentation](https://eslint.org/docs/latest/)
- [Hadolint Documentation](https://github.com/hadolint/hadolint)
- [ERB Lint Documentation](https://github.com/Shopify/erb-lint)
- [Ruby Style Guide](https://rubystyle.guide/)

---

## Related Documentation

- [Ruby Coding Patterns](../../technical_spec/ruby_patterns/README.md)
- [Stimulus Usage Guidelines](../frontend/stimulus-usage-guidelines.md)
- [Turbo Patterns](../frontend/turbo-patterns.md)
- [Testing Guide](../testing/testing-guide.md)
