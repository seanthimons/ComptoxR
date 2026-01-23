# Schema Coverage Badges

This directory contains the badge data files for displaying CCD (CompTox Chemical Dashboard) and Cheminformatic schema coverage in the README.

## What are Schema Coverage Badges?

Schema coverage badges show the percentage of API endpoints that have been implemented as R wrapper functions in this package. They help track the progress of API coverage and identify which services need more wrapper functions.

## How It Works

1. **Schemas**: The `schema/` directory contains JSON schema files for various APIs:
   - `ctx-*-prod.json`: CompTox Chemical Dashboard (CCD) API schemas (140 total endpoints across all services)
   - `chemi-*-prod.json`: Cheminformatic services schemas (192 total endpoints across all services)

2. **R Functions**: The `R/` directory contains wrapper functions:
   - `ct_*` functions: CompTox Chemical Dashboard (CCD) wrappers (111 functions)
   - `chemi_*` functions: Cheminformatic wrappers (145 functions)

3. **Coverage Calculation**: The `dev/calculate_coverage.R` script:
   - Counts API endpoints from schema files
   - Counts implemented R wrapper functions
   - Calculates coverage percentage: (functions / endpoints) × 100%
   - Determines badge color based on coverage level
   - Caps coverage at 100% to avoid confusing percentages

4. **Badge Updates**: The `.github/workflows/update-coverage-badges.yml` workflow:
   - Runs on releases, weekly schedule, or manual trigger
   - Executes the coverage calculation script
   - Updates badge JSON files in this directory
   - Updates badge URLs in README.md

## Badge Colors

Badge colors reflect the coverage level:
- **Bright Green** (≥80%): Excellent coverage
- **Green** (≥60%): Good coverage
- **Yellow** (≥40%): Moderate coverage
- **Orange** (≥20%): Low coverage
- **Red** (<20%): Very low coverage

## Current Coverage

- **CCD Coverage**: 79.3% (111 functions / 140 endpoints)
  - CompTox Chemical Dashboard (ct_* functions covering ctx-* schemas)
- **Cheminformatic Coverage**: 75.5% (145 functions / 192 endpoints)
  - Note: Coverage is capped at 100%. Multiple wrapper functions per endpoint do not increase coverage beyond 100%

## Manual Update

To manually update the badges:

1. Run the workflow manually from GitHub Actions:
   - Go to Actions → Update Schema Coverage Badges → Run workflow

2. Or run locally:
   ```bash
   Rscript dev/calculate_coverage.R
   ```

## Badge Files

- `ccd-coverage.json`: CCD coverage badge data
- `chemi-coverage.json`: Cheminformatic coverage badge data

These files follow the [shields.io endpoint badge format](https://shields.io/endpoint).
