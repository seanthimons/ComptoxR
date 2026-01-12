# GitHub Actions Workflows

This directory contains CI/CD workflows for automated testing and coverage reporting.

## Workflows

### 1. `test-coverage.yml` - Comprehensive Test Suite
**Triggers:** Push to main/dev branches, PRs to main/dev

Runs the full test suite across multiple platforms and R versions:
- **Platforms:** Ubuntu, Windows, macOS
- **R Versions:** release, devel
- **Actions:**
  - R CMD check (comprehensive package validation)
  - Run all tests
  - Calculate coverage (Ubuntu + release only)
  - Upload to Codecov

**Badge:**
```markdown
[![Test Coverage](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/test-coverage.yml/badge.svg)](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/test-coverage.yml)
```

### 2. `coverage-check.yml` - Coverage Threshold Enforcement
**Triggers:** Push to main/dev, PRs to main

Enforces minimum coverage requirements:
- **Minimum:** 70% (fails CI if below)
- **Warning:** 80% (passes but warns)
- **Target:** 90% (ideal coverage)

Also posts coverage report as PR comment.

**Badge:**
```markdown
[![Coverage Check](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/coverage-check.yml/badge.svg)](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/coverage-check.yml)
```

### 3. `test-quick.yml` - Quick Tests
**Triggers:** PRs to main/dev, push to dev-* branches

Runs fast subset of tests for quick feedback:
- Only core template tests
- Syntax checking
- No multi-platform testing
- ~2-3 minutes vs. 15-20 minutes

## Setup Requirements

### 1. GitHub Secrets

Add these secrets to your repository:

```bash
Settings → Secrets and variables → Actions → New repository secret
```

**Required Secrets:**

1. **`CTX_API_KEY`** - CompTox Dashboard API key
   - Get from: ccte_api@epa.gov
   - Used to record VCR cassettes in CI
   - Falls back to cassettes if not set

2. **`CODECOV_TOKEN`** (Optional) - Codecov upload token
   - Get from: https://codecov.io/
   - Only needed if using Codecov for coverage reporting
   - Can be omitted if not using Codecov

**To add secrets:**
1. Go to: `https://github.com/YOUR_USERNAME/ComptoxR/settings/secrets/actions`
2. Click "New repository secret"
3. Name: `CTX_API_KEY`, Value: `your_api_key_here`
4. Click "Add secret"

### 2. Codecov Integration (Optional)

If you want coverage badges and reports:

1. Go to https://codecov.io/
2. Sign in with GitHub
3. Enable Codecov for ComptoxR repo
4. Copy the upload token
5. Add as `CODECOV_TOKEN` secret in GitHub

### 3. Badge Setup

Add badges to your `README.md`:

```markdown
# ComptoxR

[![R-CMD-check](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/test-coverage.yml/badge.svg)](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/test-coverage.yml)
[![codecov](https://codecov.io/gh/YOUR_USERNAME/ComptoxR/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USERNAME/ComptoxR)
[![Coverage Check](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/coverage-check.yml/badge.svg)](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/coverage-check.yml)
```

## Usage

### Automatic Triggers

Workflows run automatically on:
- Push to `main` or `dev` branches
- Pull requests to `main` or `dev`
- Push to any `dev-*` branch (quick tests only)

### Manual Triggers

Run workflows manually:
1. Go to Actions tab
2. Select workflow
3. Click "Run workflow"
4. Choose branch
5. Click "Run workflow"

### Local Simulation

Test locally before pushing:

```r
# Run what CI will run
devtools::check()
devtools::test()
cov <- covr::package_coverage()
print(cov)
```

## Workflow Behavior

### With VCR Cassettes (Normal)

If cassettes exist in `tests/testthat/fixtures/`:
- Tests use recorded responses
- No API key needed
- Fast execution
- Consistent results

### Without Cassettes (First Run)

If cassettes don't exist:
- Tests hit production API
- Requires `CTX_API_KEY` secret
- Records responses to cassettes
- Slower first run

**To re-record cassettes:**
1. Delete cassettes: `git rm tests/testthat/fixtures/*.yml`
2. Commit and push
3. CI will re-record from production

### Coverage Thresholds

| Coverage | Status | CI Behavior |
|----------|--------|-------------|
| < 70% | ❌ Fail | Build fails, blocks merge |
| 70-79% | ⚠️ Warning | Build passes, shows warning |
| 80-89% | ✅ Pass | Build passes |
| ≥ 90% | 🎉 Excellent | Build passes with praise |

## Troubleshooting

### Tests fail with "No API key"

**Problem:** Tests try to hit API but no key set

**Solution:**
1. Add `CTX_API_KEY` secret to GitHub
2. Or commit VCR cassettes so tests don't need API

### Cassettes not found in CI

**Problem:** Cassettes not committed to repo

**Solution:**
```bash
git add tests/testthat/fixtures/*.yml
git commit -m "Add VCR cassettes for CI"
git push
```

### Coverage not uploading to Codecov

**Problem:** Codecov token not set or incorrect

**Solution:**
1. Verify `CODECOV_TOKEN` secret exists
2. Check token is correct at https://codecov.io/
3. Or remove Codecov step if not using it

### Workflow taking too long

**Problem:** Full test suite on all platforms is slow

**Solution:**
- Push to `dev-*` branch to trigger only quick tests
- Or use draft PRs to skip CI initially
- Or disable matrix testing for dev branches:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest]  # Only one platform for dev
```

## Maintenance

### Updating R Version

Edit workflow files to change R version:

```yaml
matrix:
  r-version: ['4.3', '4.4', 'devel']  # Specific versions
  # or
  r-version: ['release', 'devel']     # Latest release + devel
```

### Adjusting Coverage Thresholds

Edit `coverage-check.yml`:

```r
MINIMUM_COVERAGE <- 70  # Fail if below this
WARNING_COVERAGE <- 80  # Warn if below this
TARGET_COVERAGE <- 90   # Ideal target
```

### Adding More Platforms

Add to matrix in `test-coverage.yml`:

```yaml
matrix:
  os: [ubuntu-latest, windows-latest, macOS-latest, ubuntu-20.04]
```

## Resources

- [GitHub Actions for R](https://github.com/r-lib/actions)
- [R-CMD-check Documentation](https://r-pkgs.org/r-cmd-check.html)
- [VCR Package](https://docs.ropensci.org/vcr/)
- [Codecov Documentation](https://docs.codecov.com/)
