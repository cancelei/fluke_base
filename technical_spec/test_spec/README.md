# Testing Specifications

This directory contains comprehensive testing documentation that complements the implementation patterns documented in the parent technical specifications.

## Directory Structure

- **`ruby_testing/`** - Testing patterns for Ruby models, controllers, services, and forms
- **`turbo_testing/`** - Testing patterns for Turbo Frames, Streams, and real-time features  
- **`stimulus_testing/`** - Testing patterns for Stimulus controllers and JavaScript interactions

## Purpose

Each testing folder provides:
1. **Current Testing Patterns**: Documentation of existing test patterns used in the FlukeBase codebase
2. **Test Implementation Examples**: Real test code from the repository with explanations
3. **Testing Best Practices**: How to apply testing for the features demonstrated in parent documentation
4. **Framework Integration**: RSpec, Capybara, and JavaScript testing approaches

## Cross-References

Testing documentation is directly linked to parent implementation files:
- `ruby_testing/` ↔ `../ruby_patterns/`
- `turbo_testing/` ↔ `../hotwire_turbo/`  
- `stimulus_testing/` ↔ `../stimulus/`

## Testing Framework Overview

FlukeBase uses:
- **RSpec** - Primary testing framework for Ruby code
- **Capybara** - Integration and system testing
- **FactoryBot** - Test data generation
- **Shoulda Matchers** - Rails-specific matchers
- **JavaScript Testing** - Browser-based testing for Stimulus controllers

## Usage for AI Agents

When implementing features from the technical specifications:
1. Reference the corresponding testing documentation
2. Follow the established test patterns
3. Use the provided test examples as templates
4. Ensure coverage for both implementation and edge cases

## Coverage Strategy (Unified)

- Primary focus: Models, Services, Controllers (and Forms/Queries) to quickly lift coverage.
- Secondary focus: Helpers, Presenters, Policies/Validators; end-to-end flows to exercise controller/view paths.
- Unified coverage commands:
  - `bundle exec rake coverage:all` – runs RSpec with `COVERAGE=true` and Playwright with backend coverage, then merges into `coverage/combined/`.
  - `npm run test:e2e:cov` – E2E backend coverage only.
- CI uploads artifacts for Playwright (HTML report, traces, videos, screenshots) on failure and merged coverage.
- Ratchet plan:
  - Phase 1 target: ≥60% lines combined; primary groups ≥65%.
  - Phase 2 target: ≥70% lines combined; secondary groups ≥70%.
  - Phase 3 folds JS coverage and raises threshold to ≥75%.
