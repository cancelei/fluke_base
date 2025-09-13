# Branch Protection Configuration

This document outlines the recommended branch protection rules for the FlukeBase repository.

## Recommended Settings

### Main Branch (`main`)
- **Require status checks to pass before merging**: ✅
  - `lint` (from GitHub Actions)
- **Require branches to be up to date before merging**: ✅
- **Require pull request reviews before merging**: ✅
  - Required number of reviewers: 1
- **Dismiss stale reviews when new commits are pushed**: ✅
- **Require review from code owners**: ✅ (if CODEOWNERS file exists)
- **Restrict pushes that create files**: ❌
- **Allow force pushes**: ❌
- **Allow deletions**: ❌

### Develop Branch (`develop`)
- **Require status checks to pass before merging**: ✅
  - `lint` (from GitHub Actions)
- **Require branches to be up to date before merging**: ✅
- **Require pull request reviews before merging**: ✅
  - Required number of reviewers: 1
- **Dismiss stale reviews when new commits are pushed**: ✅
- **Restrict pushes that create files**: ❌
- **Allow force pushes**: ❌
- **Allow deletions**: ❌

## Setup Instructions

1. Go to your repository on GitHub
2. Navigate to Settings → Branches
3. Click "Add rule" or "Add branch protection rule"
4. Configure the rules as specified above
5. Save the changes

## Status Checks

The following status checks will be required:
- **`lint`**: Runs all linters (RuboCop, Brakeman, ERB Lint, ESLint)

## Benefits

- **Code Quality**: Ensures all code meets quality standards
- **Security**: Prevents security issues from being merged
- **Consistency**: Maintains consistent code style across the project
- **Automation**: Reduces manual review burden
- **Fast Feedback**: Developers get immediate feedback on issues

## Local Development

Before pushing, always run:
```bash
./bin/lint          # Check for issues
./bin/lint --fix    # Auto-fix issues
```

## Troubleshooting

If the status check fails:
1. Check the Actions tab for detailed error messages
2. Run `./bin/lint` locally to reproduce the issue
3. Fix the issues and push again
4. The status check will automatically re-run

## Customization

You can modify these rules based on your team's needs:
- Add more required status checks
- Change the number of required reviewers
- Add additional protected branches
- Configure different rules for different branches
