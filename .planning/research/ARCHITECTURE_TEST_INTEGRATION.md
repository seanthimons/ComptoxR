# Architecture Research: Test Integration for Stub Generation Pipeline

**Domain:** R package testing for development utilities
**Researched:** 2026-01-29
**Overall confidence:** HIGH

## Executive Summary

The stub generation pipeline lives in `dev/endpoint_eval/` (8 files, ~755 lines) and is excluded from package installation via `.Rbuildignore`. This code is critical for package maintenance but not distributed to users. To achieve CRAN/rOpenSci readiness, we need comprehensive test coverage for this pipeline.

**Key architectural decision:** Pipeline tests should live in `tests/testthat/test-pipeline-*.R`, source dev/ code via helper files, and integrate with existing GHA workflows with minimal modification.

This architecture leverages:
- **testthat special files** (helper.R) to source dev/ code before test execution
- **Existing vcr infrastructure** for consistent mocking patterns
- **Coverage exclusion** (.covrignore) to properly report pipeline vs. package coverage
- **Minimal GHA changes** to run pipeline tests alongside existing tests

## Test Organization

### File Location and Naming

**Location:** `tests/testthat/test-pipeline-*.R`

**Naming convention:**
```
tests/testthat/
├── test-pipeline-schema-resolution.R     # Tests 01_schema_resolution.R
├── test-pipeline-path-utils.R            # Tests 02_path_utils.R
├── test-pipeline-codebase-search.R       # Tests 03_codebase_search.R
├── test-pipeline-openapi-parser.R        # Tests 04_openapi_parser.R
├── test-pipeline-file-scaffold.R         # Tests 05_file_scaffold.R
├── test-pipeline-param-parsing.R         # Tests 06_param_parsing.R
├── test-pipeline-stub-generation.R       # Tests 07_stub_generation.R
├── test-pipeline-integration.R           # End-to-end pipeline tests
└── helper-pipeline.R                     # Sources dev/ code (see below)
```

**Rationale:**
- Follows existing convention (`test-*.R` in tests/testthat/)
- `test-pipeline-` prefix clearly distinguishes pipeline tests from wrapper tests
- One test file per dev/ module for focused testing
- `test-pipeline-integration.R` for end-to-end workflows
- Alphabetical execution ensures helper runs before tests

### Test Structure Pattern

Each pipeline test file follows this structure:

```r
# Tests for dev/endpoint_eval/01_schema_resolution.R
# Tests schema preprocessing and reference resolution functions

test_that("preprocess_schema filters excluded endpoints", {
  # Test uses fixtures in tests/testthat/fixtures/schemas/
  schema <- preprocess_schema("path/to/test_schema.json")
  expect_false(any(grepl("preflight", names(schema$paths))))
})

test_that("resolve_schema_ref handles Swagger 2.0 definitions", {
  # Mock schema with definitions
  components <- list(definitions = list(Chemical = list(type = "object")))
  result <- resolve_schema_ref("#/definitions/Chemical", components,
                                schema_version = list(type = "swagger"))
  expect_equal(result$type, "object")
})

test_that("validate_schema_ref aborts on invalid references", {
  expect_error(validate_schema_ref(""), "empty or non-character")
  expect_error(validate_schema_ref("external.json#/schemas/Foo"), "External file")
})
```

**Key patterns:**
- No VCR cassettes needed (dev/ code doesn't make HTTP requests)
- Use test fixtures for OpenAPI schemas (stored in `tests/testthat/fixtures/schemas/`)
- Test pure functions with clear inputs/outputs
- Use `expect_error()` for validation functions
- Use `expect_warning()` for fallback scenarios

## Sourcing Strategy

### Challenge

Dev/ code is not part of the installed package namespace. Tests need access to functions like `preprocess_schema()`, `resolve_schema_ref()`, `generate_stub()`, etc.

### Solution: Helper File Pattern

**File:** `tests/testthat/helper-pipeline.R`

**Execution order:**
1. `tests/testthat/setup.R` runs (existing - configures environment)
2. `tests/testthat/helper-*.R` files load (including helper-pipeline.R)
3. `tests/testthat/test-*.R` files execute

**Content:**

```r
# helper-pipeline.R
# Sources dev/endpoint_eval/ code for pipeline testing
# Loaded by devtools::test() and test_check() before tests run

# Source all pipeline files in dependency order
pipeline_files <- c(
  "00_config.R",
  "01_schema_resolution.R",
  "02_path_utils.R",
  "03_codebase_search.R",
  "04_openapi_parser.R",
  "05_file_scaffold.R",
  "06_param_parsing.R",
  "07_stub_generation.R"
)

pipeline_dir <- here::here("dev", "endpoint_eval")

for (file in pipeline_files) {
  source(file.path(pipeline_dir, file), local = FALSE)
}

# Optional: Create test fixtures directory if needed
fixtures_dir <- here::here("tests", "testthat", "fixtures", "schemas")
if (!dir.exists(fixtures_dir)) {
  dir.create(fixtures_dir, recursive = TRUE)
}
```

**Why helper.R not setup.R:**
- Helper files are sourced by `devtools::load_all()` (available during interactive development)
- Setup files only run during test execution (not available interactively)
- This matches existing pattern (`helper-vcr.R`, `helper-api.R`)

### Alternative: In-Package Helper

**Alternative approach:** Move pipeline helpers to `R/testthat-helpers.R` (within package namespace)

```r
# R/testthat-helpers.R
#' @keywords internal
source_pipeline_code <- function() {
  pipeline_files <- c("00_config.R", ...) # same as above
  for (file in pipeline_files) {
    source(here::here("dev", "endpoint_eval", file), local = FALSE)
  }
}
```

Then in tests:
```r
# test-pipeline-*.R
if (identical(Sys.getenv("DEVTOOLS_LOAD"), "true")) {
  source_pipeline_code()
}
```

**Recommendation:** Use helper-pipeline.R approach. It's simpler, follows existing patterns, and doesn't pollute package namespace with internal testing utilities.

## Test Fixtures

Pipeline tests require OpenAPI schema fixtures for testing parser functions.

### Fixture Organization

```
tests/testthat/fixtures/schemas/
├── minimal_swagger2.json      # Minimal Swagger 2.0 schema
├── minimal_openapi3.json      # Minimal OpenAPI 3.0 schema
├── complex_refs.json          # Complex nested $ref scenarios
├── circular_refs.json         # Circular reference test case
├── invalid_schema.json        # Malformed schema for error testing
└── README.md                  # Documents fixture purpose and source
```

### Fixture Creation Strategy

**Option 1:** Extract from real CompTox/Chemi schemas
```r
# Generate minimal fixture from production schema
schema <- jsonlite::fromJSON("schema/comptox_dashboard_openapi.json")
minimal <- list(
  swagger = schema$swagger,
  paths = schema$paths[1:2],  # Just 2 endpoints
  definitions = schema$definitions[1:3]  # Just 3 schemas
)
jsonlite::write_json(minimal, "tests/testthat/fixtures/schemas/minimal_swagger2.json")
```

**Option 2:** Handcraft minimal schemas
```json
{
  "swagger": "2.0",
  "paths": {
    "/test": {
      "post": {
        "parameters": [{
          "in": "body",
          "schema": {"$ref": "#/definitions/TestSchema"}
        }]
      }
    }
  },
  "definitions": {
    "TestSchema": {
      "type": "object",
      "properties": {
        "id": {"type": "string"}
      }
    }
  }
}
```

**Recommendation:** Mix both. Use real extracts for integration tests, handcrafted for edge cases.

## Coverage Integration

### Current State

- GHA workflow runs `covr::package_coverage()` on ubuntu-latest/release
- Coverage threshold: 70% minimum, 90% target
- No `.covrignore` file exists (implicit: only R/ code covered)

### Challenge

Pipeline code in `dev/` is not part of package coverage by default (not in R/ directory). We need:
1. Exclude dev/ from main package coverage (avoid false negatives)
2. Optionally report dev/ coverage separately for visibility

### Solution: .covrignore Configuration

**Create:** `.covrignore` in package root

```
# Exclude development utilities from package coverage
# These are tested separately but not distributed with package
dev/
schema/
old/
output/
```

**Add to .Rbuildignore:**
```
^\.covrignore$
```

**Rationale:**
- Explicitly excludes dev/ from package coverage calculations
- Aligns with .Rbuildignore (dev/ already excluded from build)
- Prevents misleading coverage reports ("why is coverage 0% for dev/?" noise)

### Separate Pipeline Coverage Report (Optional)

For CI visibility into pipeline test quality:

**Add to `.github/workflows/coverage-check.yml`:**

```yaml
- name: Calculate pipeline coverage
  run: |
    # Source pipeline code and calculate coverage for it
    pipeline_cov <- covr::file_coverage(
      c(
        "dev/endpoint_eval/00_config.R",
        "dev/endpoint_eval/01_schema_resolution.R",
        # ... all pipeline files
      ),
      test_files = c(
        "tests/testthat/test-pipeline-schema-resolution.R",
        "tests/testthat/test-pipeline-path-utils.R",
        # ... all pipeline test files
      )
    )

    pipeline_pct <- covr::percent_coverage(pipeline_cov)
    cat(sprintf("\n🔧 Pipeline Coverage: %.2f%%\n", pipeline_pct))

    if (pipeline_pct < 80) {
      cat(sprintf("⚠️  WARNING: Pipeline coverage (%.2f%%) below 80%%\n", pipeline_pct))
    }
  shell: Rscript {0}
```

**Why optional:**
- Main package coverage remains clean (R/ only)
- Pipeline coverage reported separately for dev transparency
- Not required for CRAN/rOpenSci (dev/ not distributed)

**Recommendation:** Implement this for milestone validation, remove after stable.

## GHA Integration

### Existing Workflows

**Test execution:**
- `test-coverage.yml` - Multi-OS, multi-R-version testing + coverage
- `R-CMD-check.yml` - Standard R CMD check
- `coverage-check.yml` - Enforces 70% minimum coverage threshold

**Current test command:**
```yaml
- name: Run tests
  run: Rscript -e 'devtools::test()'
```

### Required Changes

**None for basic integration.** Pipeline tests run automatically because:
1. `test-pipeline-*.R` files in tests/testthat/ are discovered by testthat
2. `helper-pipeline.R` sources dev/ code before tests execute
3. `devtools::test()` runs all test-*.R files

### Optional Enhancements

**1. Explicit pipeline test stage (for visibility):**

```yaml
- name: Run package tests
  run: Rscript -e 'devtools::test(filter = "^(?!pipeline)", perl = TRUE)'

- name: Run pipeline tests
  run: Rscript -e 'devtools::test(filter = "pipeline")'
```

**Why:** Separates pipeline test failures from wrapper test failures in CI logs.

**2. Pipeline-specific check on schema changes:**

Create `.github/workflows/pipeline-check.yml`:

```yaml
name: Pipeline Tests

on:
  push:
    paths:
      - 'dev/endpoint_eval/**'
      - 'tests/testthat/test-pipeline-*.R'
      - 'tests/testthat/helper-pipeline.R'

jobs:
  pipeline-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
      - name: Install dependencies
        run: Rscript -e 'install.packages(c("testthat", "here", "jsonlite", "cli", ...))'
      - name: Run pipeline tests
        run: Rscript -e 'devtools::test(filter = "pipeline")'
```

**Why:** Fast feedback when dev/ code changes (doesn't run full test suite).

**Recommendation:** Start with no changes. Add explicit stages only if pipeline tests cause noise in main CI.

## Build Order

Suggested implementation sequence for minimal risk:

### Phase 1: Foundation (Week 1)
**Goal:** Establish sourcing infrastructure and one simple test

1. Create `tests/testthat/helper-pipeline.R` (sources dev/ code)
2. Create `tests/testthat/fixtures/schemas/minimal_swagger2.json`
3. Write `test-pipeline-config.R` (test 00_config.R helpers like `%||%`, `ensure_cols`)
4. Verify tests run: `devtools::test(filter = "pipeline-config")`

**Success criteria:**
- Helper loads without errors
- One pipeline test passes
- No impact on existing tests

### Phase 2: Core Functions (Week 2)
**Goal:** Test critical path functions

5. Write `test-pipeline-schema-resolution.R`
   - `preprocess_schema()`
   - `validate_schema_ref()`
   - `resolve_schema_ref()` (Swagger 2.0 and OpenAPI 3.0 paths)
   - `detect_schema_version()`

6. Write `test-pipeline-openapi-parser.R`
   - `extract_body_properties()`
   - `extract_query_params_with_refs()`
   - Edge cases (arrays, nested objects, circular refs)

7. Create additional fixtures as needed

**Success criteria:**
- 80%+ coverage for tested modules
- Edge cases covered (circular refs, invalid schemas)
- Tests pass on all platforms (Windows, macOS, Linux)

### Phase 3: Remaining Modules (Week 3)
**Goal:** Complete coverage for all modules

8. Write `test-pipeline-path-utils.R`
9. Write `test-pipeline-codebase-search.R`
10. Write `test-pipeline-file-scaffold.R`
11. Write `test-pipeline-param-parsing.R`
12. Write `test-pipeline-stub-generation.R`

**Success criteria:**
- All 7 modules have test files
- 80%+ coverage per module

### Phase 4: Integration (Week 4)
**Goal:** End-to-end pipeline validation

13. Write `test-pipeline-integration.R`
    - Schema → Parse → Generate → Validate cycle
    - Multi-endpoint generation
    - Error propagation through pipeline

14. Create `.covrignore` (exclude dev/ from main coverage)

**Success criteria:**
- Integration tests validate complete workflows
- Coverage report shows realistic package coverage (dev/ excluded)

### Phase 5: CI Hardening (Week 5)
**Goal:** Production-ready CI integration

15. Add pipeline coverage calculation to `coverage-check.yml` (optional)
16. Verify all GHA workflows pass
17. Document pipeline testing in CLAUDE.md

**Success criteria:**
- All workflows green
- Coverage thresholds met
- Documentation complete

## Anti-Patterns to Avoid

### 1. Don't Test Implementation Details

**Bad:**
```r
test_that("resolve_stack environment has correct structure", {
  expect_true(is.environment(resolve_stack))
  expect_true(resolve_stack$hash)
})
```

**Good:**
```r
test_that("resolve_schema_ref detects circular references", {
  # Create schema with circular ref
  schema <- list(Foo = list(`$ref` = "#/definitions/Bar"),
                 Bar = list(`$ref` = "#/definitions/Foo"))
  expect_warning(resolve_schema_ref("#/definitions/Foo", schema), "Circular")
})
```

**Why:** Tests behavior, not implementation. Implementation can change without breaking tests.

### 2. Don't Duplicate Production Schemas in Fixtures

**Bad:**
```r
# Copy entire 50KB production schema to fixtures/
schema <- jsonlite::fromJSON("schema/comptox_dashboard_openapi.json")
writeLines(jsonlite::toJSON(schema, auto_unbox = TRUE),
           "tests/testthat/fixtures/schemas/production_full.json")
```

**Good:**
```r
# Extract minimal subset with relevant structures
minimal <- list(
  swagger = schema$swagger,
  paths = schema$paths[c("/chemical/detail", "/hazard")],
  definitions = schema$definitions[c("Chemical", "Hazard")]
)
```

**Why:** Faster tests, clearer intent, easier maintenance.

### 3. Don't Source dev/ Code in Individual Test Files

**Bad:**
```r
# test-pipeline-schema-resolution.R
source(here::here("dev/endpoint_eval/00_config.R"))
source(here::here("dev/endpoint_eval/01_schema_resolution.R"))

test_that("...", { ... })
```

**Good:**
```r
# Rely on helper-pipeline.R to source code
test_that("...", { ... })
```

**Why:** DRY principle. Centralized sourcing ensures correct order and no duplication.

### 4. Don't Conflate Package Tests and Pipeline Tests

**Bad:**
```r
# test-ct_hazard.R
test_that("ct_hazard uses schemas correctly", {
  # Suddenly testing schema parsing logic...
  schema <- preprocess_schema(...)
  expect_true(...)
})
```

**Good:**
```r
# test-ct_hazard.R - tests wrapper behavior only
test_that("ct_hazard returns tibble", {
  vcr::use_cassette("ct_hazard_single", {
    result <- ct_hazard("DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})

# test-pipeline-schema-resolution.R - tests pipeline logic
test_that("preprocess_schema filters endpoints", {
  schema <- preprocess_schema("fixtures/minimal_swagger2.json")
  expect_false(any(grepl("preflight", names(schema$paths))))
})
```

**Why:** Clear separation of concerns. Package tests validate user-facing behavior. Pipeline tests validate internal tooling.

## Component Boundaries

### Existing Components (Unchanged)

| Component | Responsibility | Test Location |
|-----------|---------------|---------------|
| R/*.R | Package functions (user-facing) | tests/testthat/test-{function}.R |
| tests/testthat/helper-vcr.R | VCR configuration and cassette management | N/A (tested indirectly) |
| tests/testthat/helper-api.R | Skip helpers and expectations | N/A (tested indirectly) |
| tests/testthat/setup.R | Test environment configuration | N/A (runs before tests) |
| tests/testthat/tools/*.R | Test generators (metadata extraction) | Not tested (dev tooling) |

### New Components (This Milestone)

| Component | Responsibility | Test Location |
|-----------|---------------|---------------|
| dev/endpoint_eval/*.R | Stub generation pipeline | tests/testthat/test-pipeline-*.R |
| tests/testthat/helper-pipeline.R | Sources dev/ code for tests | N/A (helper file) |
| tests/testthat/fixtures/schemas/*.json | OpenAPI schema test fixtures | Used by test-pipeline-*.R |
| .covrignore | Excludes dev/ from coverage | N/A (configuration) |

### Component Interactions

```
Test Execution Flow:
┌─────────────────────────────────────────────────────┐
│ devtools::test() or R CMD check                     │
└────────────────┬────────────────────────────────────┘
                 │
                 ├─► 1. Load package (devtools::load_all or installed)
                 │
                 ├─► 2. Source tests/testthat/setup.R
                 │      (sets environment variables)
                 │
                 ├─► 3. Source tests/testthat/helper-*.R
                 │      ├─ helper-vcr.R (VCR config)
                 │      ├─ helper-api.R (skip helpers)
                 │      └─ helper-pipeline.R (NEW - sources dev/)
                 │
                 └─► 4. Execute tests/testthat/test-*.R (alphabetically)
                        ├─ test-ct_*.R (package function tests)
                        └─ test-pipeline-*.R (NEW - pipeline tests)
```

**Key insight:** Pipeline tests integrate seamlessly because they follow existing patterns (helper files, test files in testthat/).

## Data Flow

### Package Function Tests (Existing)

```
User → ct_hazard() → generic_request() → httr2 → EPA API
                                              ↓
                                    VCR cassette (mocked)
                                              ↓
                                        tibble result
                                              ↓
                                    testthat expectations
```

### Pipeline Tests (New)

```
Test → preprocess_schema() → JSON fixture
                     ↓
              Filtered schema
                     ↓
     resolve_schema_ref() → Mock components
                     ↓
            Resolved schema
                     ↓
         testthat expectations
```

**No HTTP requests.** Pipeline tests are pure functions operating on JSON fixtures.

## Sources

### Official Documentation
- [testthat Special Files](https://testthat.r-lib.org/articles/special-files.html) - Helper and setup file execution order
- [testthat Package Documentation (CRAN, 2026-01-11)](https://cran.r-project.org/web/packages/testthat/testthat.pdf) - Test execution details
- [R Packages (2e): Testing Basics](https://r-pkgs.org/testing-basics.html) - Best practices for test organization
- [Helper Code and Files for Tests - R-hub blog](https://blog.r-hub.io/2020/11/18/testthat-utility-belt/) - Helper file patterns

### Coverage Tools
- [covr Package Documentation](https://covr.r-lib.org/) - Coverage calculation and exclusions
- [covr GitHub Repository](https://github.com/r-lib/covr) - .covrignore file documentation
- [package_coverage() Documentation](https://rdrr.io/cran/covr/man/package_coverage.html) - Coverage configuration options

### Test Directory Patterns
- [testthat test_dir() Documentation](https://testthat.r-lib.org/reference/test_dir.html) - Low-level test execution
- [devtools test() Documentation](https://devtools.r-lib.org/reference/test.html) - High-level test execution with load_all()

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Test organization | HIGH | Follows established testthat patterns, aligned with existing codebase structure |
| Sourcing strategy | HIGH | Helper file pattern is documented and widely used in R packages |
| Coverage configuration | HIGH | .covrignore is official covr feature with clear documentation |
| GHA integration | HIGH | No workflow changes needed for basic integration; optional enhancements documented |
| Build order | MEDIUM | Phased approach is logical, but timeline estimates depend on complexity discovery |

## Open Questions

None. Architecture is well-defined and leverages existing R package testing infrastructure. Implementation can proceed with high confidence.

## Ready for Roadmap

Research complete. Architecture leverages existing testthat infrastructure (helper files, fixtures, test discovery) with minimal modifications to CI/CD. Pipeline tests integrate seamlessly alongside existing wrapper tests while maintaining clear separation of concerns.

**Recommended first step:** Create `helper-pipeline.R` and `test-pipeline-config.R` to validate sourcing strategy before expanding to other modules.
