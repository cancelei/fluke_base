# Technical Specifications

This directory contains comprehensive documentation of implementation patterns used in the FlukeBase codebase, designed to help future AI agents quickly understand and implement similar functionality.

## Directory Structure

- **`ruby_patterns/`** - Ruby coding patterns and best practices with examples
- **`hotwire_turbo/`** - Complete Hotwire Turbo implementation patterns
- **`stimulus/`** - Stimulus controller patterns and JavaScript interactions
- **`test_spec/`** - Comprehensive testing patterns for all implementation areas
- **`validation_notes/`** - Notes comparing our patterns with official documentation

## Purpose

Each folder contains:
1. Pattern documentation with real codebase examples
2. Implementation guides with file references
3. Best practices and common pitfalls
4. Links to official documentation for validation

The `test_spec/` directory provides complementary testing documentation:
- **`ruby_testing/`** - Model, controller, service, and form object testing patterns
- **`turbo_testing/`** - Turbo Frame, Stream, and real-time feature testing
- **`stimulus_testing/`** - JavaScript controller and interaction testing patterns

## Usage for AI Agents

When implementing similar functionality:
1. Check the relevant pattern folder
2. Review the examples from our codebase
3. Follow the implementation guide
4. Reference the corresponding testing patterns in `test_spec/`
5. Validate against the referenced documentation

## Quick Navigation

**Implementation Patterns** ↔ **Testing Patterns**
- [`ruby_patterns/`](ruby_patterns/) ↔ [`test_spec/ruby_testing/`](test_spec/ruby_testing/)
- [`hotwire_turbo/`](hotwire_turbo/) ↔ [`test_spec/turbo_testing/`](test_spec/turbo_testing/)
- [`stimulus/`](stimulus/) ↔ [`test_spec/stimulus_testing/`](test_spec/stimulus_testing/)