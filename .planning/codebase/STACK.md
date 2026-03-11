# Technology Stack

**Analysis Date:** 2026-02-12

## Languages

**Primary:**
- R 3.5.0+ - EPA package providing wrappers for CompTox Chemical Dashboard APIs and related products
- Used in all source files: `R/*.R`

## Runtime

**Environment:**
- R (>= 3.5.0)

**Package Manager:**
- R package system (DESCRIPTION file for dependencies)
- Lockfile: renv.lock (optional, not detected)

## Frameworks

**Core:**
- httr2 - HTTP client for all API communications
- dplyr >= 1.1.4 - Data manipulation and tibble creation
- tidyr >= 1.3.1 - Data reshaping
- jsonlite >= 1.8.8 - JSON parsing for API responses

**CLI & Output:**
- cli - User-facing messages and formatting
- ggplot2 - Data visualization
- scales - Scaling for plots

**Utilities:**
- purrr >= 1.0.2 - Functional programming utilities
- stringr >= 1.5.1 - String manipulation
- stringi - Advanced string operations
- glue - String interpolation
- janitor >= 2.1.0 - Data cleaning
- here - Path handling
- magrittr >= 2.0.3 - Pipe operators
- rlang - Low-level R utilities
- tibble - Modern data frames
- lifecycle - Deprecation management

**Testing:**
- testthat >= 3.0.0 - Unit testing framework
- vcr - HTTP response recording/mocking
- httptest2 - HTTP testing utilities
- webmockr - HTTP mocking

**Suggested/Optional:**
- ctxR >= 1.0 - Related EPA package dependency
- webchem >= 1.3.1 - Chemical data retrieval
- withr - Safe temporary state changes
- autonewsmd - Automated NEWS.md generation for releases

**Build & Dev:**
- roxygen2 - Documentation generation (version 7.3.3 via RoxygenNote)
- devtools - Development utilities
- usethis - Workflow helpers

## Configuration

**Build Configuration:**
- roxygen2 markdown support enabled
- Encoding: UTF-8
- LazyData: true
- Config/testthat/edition: 3
- Config/testthat/parallel: true (tests can run in parallel)

**Environment:**
- `.env` file present (contains environment configuration)
- Note: Environment variables are read via `Sys.getenv()`, never hardcoded

## API Endpoint Configuration (Environment Variables)

**Set via server configuration functions:**
- `ctx_burl` - CompTox Dashboard API base URL
  - Production: `https://comptox.epa.gov/ctx-api/`
  - Staging: `https://ctx-api-stg.ccte.epa.gov/`
  - Development: `https://ctx-api-dev.ccte.epa.gov/`

- `chemi_burl` - Cheminformatics API base URL
  - Production: `https://hcd.rtpnc.epa.gov/api`
  - Staging: `https://cim.sciencedataexperts.com/api`
  - Development: `https://cim-dev.sciencedataexperts.com/api`

- `epi_burl` - EPI Suite API base URL
  - Production: `https://episuite.dev/EpiWebSuite/api`

- `eco_burl` - ECOTOX API base URL
  - Options: Dashboard, Production, or Local

- `cc_burl` - CAS Common Chemistry API base URL
  - Production: `https://commonchemistry.cas.org/api/`

- `np_burl` - Natural Products API base URL
  - Production: `https://api.naturalproducts.net/latest/`

**Authentication:**
- `ctx_api_key` - CompTox Dashboard API key (required for authenticated endpoints)
- `cc_api_key` - CAS Common Chemistry API key (required)

**Runtime Flags:**
- `run_debug` - Boolean flag for debug mode (dry-run without executing requests)
- `run_verbose` - Boolean flag for verbose logging
- `batch_limit` - Numeric batch size for POST requests (default: 200)

## Platform Requirements

**Development:**
- R 4.5.1+ recommended (from project instructions)
- Rscript.exe at `C:\Program Files\R\R-4.5.1\bin\Rscript.exe` (Windows)
- Valid API keys for production testing

**Production:**
- R >= 3.5.0
- Network access to EPA CompTox Dashboard APIs

## Testing Infrastructure

**Test Runner:**
- testthat 3.0.0+ with parallel execution enabled
- vcr for HTTP cassette recording/replay
- .vcr_config in `tests/testthat/helper-vcr.R` sanitizes API keys as `<<<API_KEY>>>`

**Cassettes:**
- Stored in `tests/testthat/fixtures/` directory
- Recorded from production on first run (requires valid API key)
- Replayed on subsequent runs (no API key needed)

## CI/CD

**GitHub Actions Workflows:**
- `.github/workflows/R-CMD-check.yml` - Package validation (Ubuntu + R release)
- `.github/workflows/test-coverage.yml` - Test execution and coverage reporting
- `.github/workflows/coverage-check.yml` - Coverage threshold enforcement
- `.github/workflows/release.yml` - Version bumping and package release
- `.github/workflows/schema-check.yml` - API schema validation
- `.github/workflows/gitleaks.yml` - Secret detection
- `.github/workflows/pipeline-tests.yml` - E2E pipeline integration tests

## Documentation

**Roxygen:**
- roxygen2 7.3.3 used for all function documentation
- Markdown support enabled via `Roxygen: list(markdown = TRUE)`
- All function documentation in function files with `@export` tags

**API Schemas:**
- OpenAPI 3.1.0 and Swagger 2.0 schemas stored in `schema/` directory
- Schemas for production, staging, and development environments
- Covers: CompTox Dashboard (ctx), Cheminformatics (chemi), EPI Suite, ECOTOX

---

*Stack analysis: 2026-02-12*
