# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated code quality checks.

## Workflows

### `lint.yml` - Main Linting Workflow
- **Triggers**: Push to `main`/`develop`, Pull Requests
- **Purpose**: Runs all linters in parallel using our unified linting system
- **Features**:
  - Uses our custom `./bin/lint` script
  - Caches dependencies and lint results for speed
  - Comments on PRs with results
  - Fails the build if any linter finds issues

### `ci.yml` - Comprehensive CI Workflow
- **Triggers**: Push to `main`/`develop`, Pull Requests
- **Purpose**: Full CI pipeline with parallel linting
- **Features**:
  - Runs each linter in separate jobs for true parallelism
  - Generates detailed summaries
  - Includes test job (disabled by default)
  - Comprehensive PR comments

### `lint-parallel.yml` - Parallel Linting
- **Triggers**: Push to `main`/`develop`, Pull Requests
- **Purpose**: Alternative parallel implementation
- **Features**:
  - Matrix strategy for parallel execution
  - Individual job results
  - Artifact collection

### `lint-unified.yml` - Simple Unified Linting
- **Triggers**: Push to `main`/`develop`, Pull Requests
- **Purpose**: Simple workflow using unified linter
- **Features**:
  - Single job execution
  - Auto-fix capability for `fix/*` branches
  - Basic PR comments

## Recommended Usage

For most projects, use **`lint.yml`** as it provides:
- ✅ Fast execution (parallel linters)
- ✅ Simple maintenance
- ✅ Good caching
- ✅ Clear PR feedback
- ✅ Uses our unified linting script

## Local Development

Before pushing, run locally:
```bash
./bin/lint          # Run all linters
./bin/lint --fix    # Auto-fix issues
```

## Configuration

The workflows are configured to:
- Use Ruby 3.2.1 and Node.js 20
- Cache dependencies and lint results
- Run on `main` and `develop` branches
- Comment on pull requests
- Fail the build if linting issues are found

## Customization

To modify the workflows:
1. Edit the appropriate `.yml` file
2. Adjust triggers, Ruby/Node versions, or caching as needed
3. Test locally with `act` if desired
4. Commit and push to trigger the workflow
