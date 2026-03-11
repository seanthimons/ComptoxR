# Phase 26: Pagination Tests & Coverage Hardening - Research

**Researched:** 2026-03-01
**Domain:** R package testing (testthat), VCR cassette testing, coverage configuration (covr)
**Confidence:** HIGH

## Summary

Phase 26 tests pagination functionality implemented in Phases 19-21 and tunes coverage thresholds for a codebase with auto-generated stubs. The testing infrastructure is already in place: testthat 3.0+ with parallel execution, vcr for HTTP mocking, and covr for coverage reporting. The project has 70 schema files and uses metadata-based test generation. Pagination detection lives in `dev/endpoint_eval/04_openapi_parser.R` (detect_pagination function) and pagination execution lives in `R/z_generic_request.R` (generic_request and generic_chemi_request functions). The PAGINATION_REGISTRY defines 7 patterns across different EPA APIs. Current coverage threshold is 70% minimum, warns at 80%, targets 90%.

This phase creates three specialized test files: detection tests (verify regex patterns against real schemas), execution tests (verify pagination loop logic with mocks), and integration tests (VCR-backed end-to-end). Coverage configuration already exists but may need exclusion patterns for auto-generated code.

**Primary recommendation:** Use testthat with VCR for integration, mockery package for execution unit tests, dynamic schema scanning for detection tests, and adjust coverage thresholds via covr exclusion patterns rather than lowering global threshold.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Test `detect_pagination()` (dev/endpoint_eval/04_openapi_parser.R) against all 7 registry patterns
- Use **real schema data** extracted from the `schema/` directory at runtime — dynamic scan, not hardcoded snapshots
- Include **negative tests**: feed non-paginated endpoints to confirm no false positives
- If schemas are not present, tests **skip gracefully** with `testthat::skip("schemas not available")`
- Add **warning + 'none' + log** behavior when params look like pagination but don't match any registry pattern (enhancement to `detect_pagination()`)
- Test each runtime pagination strategy in `generic_request()` with **mocked responses** (not real API calls)
- Strategies to cover: offset_limit (path params), offset_limit (query params), page_number, page_size, cursor
- Mocked tests verify the loop logic, record combination, and termination conditions
- Use **chemi_amos_method_pagination** as the VCR-backed integration test endpoint
- Exercise **2-3 pages** to prove the loop works without bloating cassettes
- Verify **last page behavior**: loop terminates correctly on partial/empty page
- Verify **max_pages safety limit**: set max_pages=2, confirm it stops and emits warning
- **Single threshold: 75%** for entire package
- **Warn only** in CI — report coverage but don't block merges
- **Exclude** `dev/` scripts and `data.R` from coverage measurement
- **Split by layer** into three files:
  - `test-pagination-detection.R` — regex pattern matching against schemas
  - `test-pagination-execution.R` — mocked runtime strategy tests
  - `test-pagination-integration.R` — VCR-backed end-to-end test
- All files live in `tests/testthat/` (standard R package test directory)
- VCR cassettes follow existing function-name convention (e.g., `chemi_amos_method_pagination.yml`)

### Claude's Discretion

- Exact mock response structure for execution tests
- How to source `dev/` functions in test context (source() vs test helper)
- Whether to use httptest2 or custom mocking for execution tests

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PAG-20 | Unit tests verify regex detection catches all 5 known pagination patterns from real schemas | Schema scanning + testthat structure in "Detection Tests Architecture" |
| PAG-21 | Unit tests verify each pagination strategy (offset/limit, page/size, cursor, path-based) with mocked responses | Mock response patterns in "Execution Tests Architecture" |
| PAG-22 | At least one integration test runs a paginated stub end-to-end with VCR cassettes | VCR setup in "Integration Tests Architecture" + existing chemi_amos_method_pagination example |
| PAG-23 | All existing non-pagination tests continue to pass (no regression) | No new dependencies, isolated test files prevent interference |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| testthat | >= 3.0.0 | Unit testing framework | R package standard, already configured with parallel execution |
| vcr | latest | HTTP mocking for integration tests | Already in use (706+ cassettes), filters API keys automatically |
| covr | latest | Test coverage reporting | Already integrated in CI via .github/workflows/coverage-check.yml |
| mockery | latest | Mock function calls for unit tests | Standard R mocking library for testthat |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jsonlite | >= 1.8.8 | Parse schema files | Already in Imports, needed for dynamic schema loading |
| fs | latest | File system operations | List schema files, already available via dev dependencies |
| here | latest | Path resolution | Already in Imports, needed for cross-platform schema paths |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mockery | httptest2 | httptest2 is in Suggests but not used anywhere; mockery is simpler for function-level mocking |
| vcr | httptest2 | Would require rewriting 706+ cassettes; vcr is working and API-key safe |

**Installation:**
```r
# All dependencies already in DESCRIPTION
# mockery needs to be added to Suggests:
usethis::use_package("mockery", type = "Suggests")
```

## Architecture Patterns

### Recommended Test Structure
```
tests/testthat/
├── test-pagination-detection.R    # PAG-20: Schema-based regex tests
├── test-pagination-execution.R    # PAG-21: Mocked pagination loop tests
├── test-pagination-integration.R  # PAG-22: VCR end-to-end tests
├── helper-vcr.R                    # Already exists: vcr configuration
└── fixtures/                       # Already exists: VCR cassettes
    └── chemi_amos_method_pagination_*.yml
```

### Pattern 1: Detection Tests (PAG-20)

**What:** Test `detect_pagination()` against real schema files from `schema/` directory

**When to use:** Verify that regex patterns in PAGINATION_REGISTRY correctly identify paginated endpoints

**Example:**
```r
# test-pagination-detection.R
test_that("detect_pagination identifies offset_limit_path pattern", {
  # Dynamically load schema files
  schema_dir <- here::here("schema")
  if (!dir.exists(schema_dir)) {
    skip("Schema directory not available")
  }

  # Load AMOS schema (has method_pagination endpoint)
  amos_schema <- jsonlite::read_json(
    fs::path(schema_dir, "chemi-amos-prod.json")
  )

  # Extract endpoint spec for method_pagination
  endpoint <- amos_schema$paths[["/amos/method_pagination/{limit}/{offset}"]]$get

  # Test detection
  result <- detect_pagination(
    route = "/amos/method_pagination/{limit}/{offset}",
    path_params = "limit,offset",
    query_params = "",
    body_params = ""
  )

  expect_equal(result$strategy, "offset_limit")
  expect_equal(result$param_location, "path")
  expect_equal(result$registry_key, "offset_limit_path")
})

test_that("detect_pagination returns 'none' for non-paginated endpoints", {
  result <- detect_pagination(
    route = "/chemical/detail",
    path_params = "dtxsid",
    query_params = "",
    body_params = ""
  )

  expect_equal(result$strategy, "none")
  expect_true(is.na(result$registry_key))
})
```

**Key techniques:**
- Dynamic schema loading with graceful skip if unavailable
- Test all 7 PAGINATION_REGISTRY patterns (offset_limit_path, cursor_path, page_number_query, offset_size_body, offset_size_query, page_size_query, page_items_query)
- Negative tests for non-paginated endpoints
- Source detection function: `source(here::here("dev/endpoint_eval/04_openapi_parser.R"))` in test setup

### Pattern 2: Execution Tests (PAG-21)

**What:** Test pagination loop logic in `generic_request()` with mocked HTTP responses

**When to use:** Verify pagination strategies correctly iterate, combine records, and terminate

**Example:**
```r
# test-pagination-execution.R
test_that("offset_limit path strategy paginates correctly", {
  # Mock httr2::req_perform_iterative to return 3 pages
  mock_page1 <- list(
    list(id = 1, name = "record1"),
    list(id = 2, name = "record2")
  )
  mock_page2 <- list(
    list(id = 3, name = "record3"),
    list(id = 4, name = "record4")
  )
  mock_page3 <- list(
    list(id = 5, name = "record5")
  )

  mockery::stub(
    generic_request,
    "httr2::req_perform_iterative",
    list(mock_page1, mock_page2, mock_page3)
  )

  # Call with pagination enabled
  result <- generic_request(
    query = 2,
    endpoint = "test/pagination",
    method = "GET",
    batch_limit = 1,
    path_params = c(offset = 0),
    paginate = TRUE,
    max_pages = 100,
    pagination_strategy = "offset_limit"
  )

  # Verify all records combined
  expect_equal(nrow(result), 5)
  expect_equal(result$id, 1:5)
})

test_that("pagination stops at max_pages limit", {
  # Mock infinite pages
  mockery::stub(
    generic_request,
    "httr2::req_perform_iterative",
    function(...) {
      # Return max_pages worth of full pages
      replicate(100, list(list(id = 1)), simplify = FALSE)
    }
  )

  # Expect warning about truncation
  expect_warning(
    result <- generic_request(
      query = 100,
      endpoint = "test/pagination",
      method = "GET",
      batch_limit = 1,
      paginate = TRUE,
      max_pages = 2,
      pagination_strategy = "page_number"
    ),
    "Pagination stopped at 2 page"
  )
})
```

**Key techniques:**
- Use mockery::stub() to mock httr2 functions
- Test all 5 runtime strategies: offset_limit (path), offset_limit (query), page_number, page_size, cursor
- Test termination conditions: empty page, partial page, max_pages limit
- Test record combination logic (list_flatten, safe_tidy_bind)

### Pattern 3: Integration Tests (PAG-22)

**What:** End-to-end test with real function calls and VCR cassettes

**When to use:** Verify pagination works in production with actual API responses

**Example:**
```r
# test-pagination-integration.R
test_that("chemi_amos_method_pagination fetches multiple pages", {
  vcr::use_cassette("pagination_integration_multipage", {
    # Fetch 2 pages with small limit
    result <- chemi_amos_method_pagination(
      limit = 5,
      offset = 0,
      all_pages = TRUE
    )

    expect_s3_class(result, "list")
    expect_true(length(result) >= 5)  # At least one full page
  })
})

test_that("pagination terminates on last page", {
  vcr::use_cassette("pagination_integration_lastpage", {
    # Fetch pages until exhausted
    result <- chemi_amos_method_pagination(
      limit = 1000,  # Large limit ensures we hit last page
      offset = 0,
      all_pages = TRUE
    )

    # No specific count assertion (depends on API data)
    # Just verify it returned without error
    expect_true(is.list(result))
  })
})

test_that("max_pages parameter prevents runaway loops", {
  vcr::use_cassette("pagination_integration_maxpages", {
    expect_warning(
      result <- chemi_amos_method_pagination(
        limit = 1,  # Tiny pages to trigger max_pages
        offset = 0,
        all_pages = TRUE
        # max_pages defaults to 100 in function
      ),
      "Pagination stopped"
    )
  })
})
```

**Key techniques:**
- Use existing function `chemi_amos_method_pagination` (already has pagination enabled)
- Record 2-3 pages only to keep cassette size manageable
- Test termination behavior (last page, max_pages warning)
- VCR cassettes auto-filter API keys via helper-vcr.R configuration

### Anti-Patterns to Avoid

- **Hardcoded schema snapshots:** Detection tests must load from `schema/` at runtime to catch drift
- **Testing without API key filtering:** Always use vcr configuration from helper-vcr.R (already set up)
- **Over-mocking integration tests:** VCR tests should call real functions, not mock internals
- **Bloating cassettes:** Integration tests should use small limits (1-5 records per page) for 2-3 pages only

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP response mocking | Custom mock objects | mockery::stub() + vcr | mockery integrates with testthat, vcr handles real API responses |
| Coverage exclusions | Manual file-level exclusions | covr line comments or .covrignore | covr supports inline `# nocov` comments and exclusion files |
| Test discovery | Hardcoded schema paths | fs::dir_ls() with here::here() | Cross-platform, handles missing schemas gracefully |
| Assertion helpers | Custom expect_* functions | testthat built-ins | testthat 3.0+ has expect_s3_class, expect_warning, expect_error |

**Key insight:** R testing ecosystem is mature. testthat + vcr + mockery + covr is the standard stack. Don't reinvent test infrastructure — leverage existing helpers and conventions.

## Common Pitfalls

### Pitfall 1: Testing dev/ Functions Without Loading Dependencies

**What goes wrong:** `detect_pagination()` lives in `dev/endpoint_eval/04_openapi_parser.R`, which isn't loaded by `library(ComptoxR)`

**Why it happens:** dev/ scripts are not part of the package namespace

**How to avoid:** Source the file in test setup with dependencies
```r
# At top of test-pagination-detection.R
source(here::here("dev/endpoint_eval/00_config.R"))  # Loads PAGINATION_REGISTRY
source(here::here("dev/endpoint_eval/04_openapi_parser.R"))  # Loads detect_pagination
```

**Warning signs:** Error "could not find function 'detect_pagination'"

### Pitfall 2: VCR Cassettes Recording Full Paginated Dataset

**What goes wrong:** Recording 100+ pages creates massive cassettes (MB+ in size)

**Why it happens:** Default max_pages=100 with production data pagination

**How to avoid:** Use small limits in integration tests
```r
# BAD: Records 100 pages
result <- chemi_amos_method_pagination(limit = 10, all_pages = TRUE)

# GOOD: Records 2-3 pages
result <- chemi_amos_method_pagination(limit = 1000, offset = 0, all_pages = TRUE)
# Or override max_pages in function call (requires function modification)
```

**Warning signs:** Cassette files > 100KB, slow test execution, git warnings about large files

### Pitfall 3: Mocking httr2 Internal Functions Incorrectly

**What goes wrong:** mockery::stub() fails because function signature doesn't match

**Why it happens:** httr2::req_perform_iterative has complex signature with callbacks

**How to avoid:** Mock at the right level — mock the response objects, not the iterator
```r
# BAD: Mock req_perform_iterative directly (complex signature)
mockery::stub(generic_request, "httr2::req_perform_iterative", mock_value)

# GOOD: Mock httr2::resp_body_json to return staged responses
mockery::stub(generic_request, "httr2::resp_body_json", function(resp, ...) {
  # Return different data based on call count
})
```

**Warning signs:** Error "cannot match function signature", unexpected arguments error

### Pitfall 4: Coverage Threshold Blocking CI After Adding Tests

**What goes wrong:** Adding pagination tests drops coverage because dev/ code isn't covered

**Why it happens:** Current threshold is 70% minimum, dev/ scripts excluded from measurement

**How to avoid:** Adjust coverage exclusions BEFORE adding tests
```r
# In coverage-check.yml, add exclusion patterns
covr::package_coverage(
  type = "tests",
  line_exclusions = list(
    "R/data.R" = TRUE,
    "dev/" = TRUE
  )
)
```

**Warning signs:** Coverage drops below 70% in CI, workflow fails on coverage check

### Pitfall 5: Forgetting to Skip Tests When Schemas Missing

**What goes wrong:** Tests fail in CI or other environments without schema/ directory

**Why it happens:** Schema files not committed to git (or optional dependency)

**How to avoid:** Always wrap schema-dependent tests in skip condition
```r
test_that("detect_pagination works", {
  schema_dir <- here::here("schema")
  if (!dir.exists(schema_dir)) {
    skip("Schema directory not available")
  }
  # ... test code
})
```

**Warning signs:** "cannot open file" errors in test logs, tests fail on fresh checkout

## Code Examples

### Detection Test Structure

```r
# Source: Project architecture (dev/endpoint_eval/04_openapi_parser.R)
# test-pagination-detection.R

# Load dependencies
source(here::here("dev/endpoint_eval/00_config.R"))
source(here::here("dev/endpoint_eval/04_openapi_parser.R"))

test_that("PAGINATION_REGISTRY has 7 patterns", {
  expect_equal(length(PAGINATION_REGISTRY), 7)
  expect_named(PAGINATION_REGISTRY, c(
    "offset_limit_path", "cursor_path", "page_number_query",
    "offset_size_body", "offset_size_query", "page_size_query",
    "page_items_query"
  ))
})

test_that("detect_pagination identifies all registry patterns from real schemas", {
  schema_dir <- here::here("schema")
  if (!dir.exists(schema_dir)) {
    skip("Schema directory not available")
  }

  # Test offset_limit_path (AMOS)
  result <- detect_pagination(
    route = "/amos/method_pagination/{limit}/{offset}",
    path_params = "limit,offset",
    query_params = "",
    body_params = ""
  )
  expect_equal(result$strategy, "offset_limit")
  expect_equal(result$registry_key, "offset_limit_path")

  # Test cursor_path (AMOS keyset)
  result <- detect_pagination(
    route = "/amos/similar_structures_keyset_pagination/{limit}",
    path_params = "limit",
    query_params = "cursor",
    body_params = ""
  )
  expect_equal(result$strategy, "cursor")
  expect_equal(result$registry_key, "cursor_path")

  # Test page_number_query (CTX)
  result <- detect_pagination(
    route = "/hazard",
    path_params = "",
    query_params = "pageNumber",
    body_params = ""
  )
  expect_equal(result$strategy, "page_number")

  # Test offset_size_body (Chemi Search)
  result <- detect_pagination(
    route = "/search",
    path_params = "",
    query_params = "",
    body_params = "offset,limit"
  )
  expect_equal(result$strategy, "offset_limit")
  expect_equal(result$registry_key, "offset_size_body")

  # Test offset_size_query (Common Chemistry)
  result <- detect_pagination(
    route = "/search",
    path_params = "",
    query_params = "offset,size",
    body_params = ""
  )
  expect_equal(result$strategy, "offset_limit")
  expect_equal(result$registry_key, "offset_size_query")

  # Test page_size_query (Chemi Resolver)
  result <- detect_pagination(
    route = "/resolver/classyfire",
    path_params = "",
    query_params = "page,size",
    body_params = ""
  )
  expect_equal(result$strategy, "page_size")
  expect_equal(result$registry_key, "page_size_query")

  # Test page_items_query (Chemi Resolver PubChem)
  result <- detect_pagination(
    route = "/resolver/pubchem",
    path_params = "",
    query_params = "page,itemsPerPage",
    body_params = ""
  )
  expect_equal(result$strategy, "page_size")
  expect_equal(result$registry_key, "page_items_query")
})

test_that("detect_pagination returns 'none' for non-paginated endpoints", {
  # Typical single-item GET
  result <- detect_pagination(
    route = "/chemical/detail/{dtxsid}",
    path_params = "dtxsid",
    query_params = "",
    body_params = ""
  )
  expect_equal(result$strategy, "none")

  # Bulk POST without pagination
  result <- detect_pagination(
    route = "/hazard",
    path_params = "",
    query_params = "projection",
    body_params = ""
  )
  expect_equal(result$strategy, "none")
})
```

### Execution Test Structure (Mocking)

```r
# Source: mockery package documentation + project generic_request patterns
# test-pagination-execution.R

test_that("offset_limit path strategy combines pages correctly", {
  # Create mock responses (simplified structure)
  mock_resp1 <- list(
    status_code = 200,
    body = list(
      list(id = 1, value = "A"),
      list(id = 2, value = "B")
    )
  )
  mock_resp2 <- list(
    status_code = 200,
    body = list(
      list(id = 3, value = "C")
    )
  )

  # Track which page we're on
  page_counter <- 0

  # Mock httr2::req_perform_iterative to return staged responses
  mockery::stub(
    generic_request,
    "httr2::req_perform_iterative",
    function(req, next_req, max_reqs, on_error, progress) {
      # Return mock response structure
      list(mock_resp1, mock_resp2)
    }
  )

  mockery::stub(
    generic_request,
    "httr2::resps_successes",
    function(resps) resps  # Pass through
  )

  mockery::stub(
    generic_request,
    "httr2::resp_body_json",
    function(resp, ...) resp$body
  )

  result <- generic_request(
    query = 10,
    endpoint = "test/pagination",
    method = "GET",
    batch_limit = 1,
    path_params = c(offset = 0),
    paginate = TRUE,
    max_pages = 100,
    pagination_strategy = "offset_limit"
  )

  # Verify combined results
  expect_equal(nrow(result), 3)
  expect_equal(result$id, 1:3)
})

test_that("pagination emits warning when max_pages reached", {
  # Mock infinite full pages
  mock_resp <- list(
    status_code = 200,
    body = replicate(100, list(id = 1, value = "X"), simplify = FALSE)
  )

  mockery::stub(
    generic_request,
    "httr2::req_perform_iterative",
    function(req, next_req, max_reqs, ...) {
      replicate(max_reqs, mock_resp, simplify = FALSE)
    }
  )

  expect_warning(
    result <- generic_request(
      query = 10,
      endpoint = "test/pagination",
      method = "GET",
      batch_limit = 1,
      paginate = TRUE,
      max_pages = 2,
      pagination_strategy = "page_number"
    ),
    "Pagination stopped at 2 page"
  )
})
```

**Note on mocking approach:** For execution tests, we need to mock httr2 functions. The exact structure will depend on testing whether we can effectively stub req_perform_iterative or need to mock at a lower level (resp_body_json). The discretion decision here is: try stubbing req_perform_iterative first (simpler), fall back to mocking response parsing if signature issues arise.

### Integration Test Structure (VCR)

```r
# Source: Existing test-chemi_amos_method_pagination.R pattern
# test-pagination-integration.R

test_that("chemi_amos_method_pagination fetches multiple pages end-to-end", {
  vcr::use_cassette("pagination_e2e_multipage", {
    result <- chemi_amos_method_pagination(
      limit = 5,   # Small page size
      offset = 0,
      all_pages = TRUE
    )

    # Verify we got list back (tidy=FALSE in function)
    expect_type(result, "list")

    # Verify we got at least one page worth of records
    expect_true(length(result) >= 5)
  })
})

test_that("pagination terminates on partial last page", {
  vcr::use_cassette("pagination_e2e_lastpage", {
    # Use large limit to ensure we hit last page in few iterations
    result <- chemi_amos_method_pagination(
      limit = 100,
      offset = 0,
      all_pages = TRUE
    )

    # Just verify it completed without error
    expect_type(result, "list")
  })
})

test_that("pagination respects max_pages parameter", {
  # This test requires modifying chemi_amos_method_pagination to expose max_pages
  # OR we test a different paginated function that already exposes it
  # For now, document the requirement
  skip("Requires exposing max_pages parameter in stub function")
})
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat (>= 3.0.0) |
| Config file | tests/testthat.R (standard setup) |
| Quick run command | `devtools::test_file("tests/testthat/test-pagination-detection.R")` |
| Full suite command | `devtools::test()` or `testthat::test_dir("tests/testthat")` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PAG-20 | Regex patterns detect pagination from schemas | unit | `devtools::test_file("tests/testthat/test-pagination-detection.R")` | ❌ Wave 0 |
| PAG-21 | Pagination strategies loop and combine correctly | unit | `devtools::test_file("tests/testthat/test-pagination-execution.R")` | ❌ Wave 0 |
| PAG-22 | End-to-end pagination with VCR | integration | `devtools::test_file("tests/testthat/test-pagination-integration.R")` | ❌ Wave 0 |
| PAG-23 | No regression in existing tests | smoke | `devtools::test()` | ✅ Existing |

### Sampling Rate
- **Per task commit:** `devtools::test_file("tests/testthat/test-pagination-*.R")` (pagination tests only, ~5 seconds)
- **Per wave merge:** `devtools::test()` (full suite, ~30 seconds with vcr cassettes)
- **Phase gate:** Full suite green + `covr::package_coverage()` reports >= 75%

### Wave 0 Gaps
- [ ] `tests/testthat/test-pagination-detection.R` — covers PAG-20 (regex detection against real schemas)
- [ ] `tests/testthat/test-pagination-execution.R` — covers PAG-21 (mocked pagination loop logic)
- [ ] `tests/testthat/test-pagination-integration.R` — covers PAG-22 (VCR end-to-end test)
- [ ] `mockery` package in DESCRIPTION Suggests — needed for execution unit tests
- [ ] Coverage exclusion configuration — adjust .github/workflows/coverage-check.yml to exclude dev/ and data.R
- [ ] Enhancement to `detect_pagination()` — add warning when params look like pagination but don't match registry

## Coverage Configuration

### Current Setup (from .github/workflows/coverage-check.yml)

```r
# Thresholds
MINIMUM_COVERAGE <- 70   # FAIL if below
WARNING_COVERAGE <- 80   # WARN if below
TARGET_COVERAGE <- 90    # Goal

# Coverage measurement
cov <- covr::package_coverage()
```

### Recommended Adjustments for Phase 26

**Option 1: Exclude dev/ and data.R via covr arguments**
```r
# In .github/workflows/coverage-check.yml, modify coverage call:
cov <- covr::package_coverage(
  type = "tests",
  line_exclusions = list(
    "R/data.R" = TRUE
  ),
  path = "R"  # Only measure R/ directory, not dev/
)
```

**Option 2: Use .covrignore file**
```
# .covrignore (create in project root)
dev/*
R/data.R
```

**Recommended approach:** Option 1 (inline exclusions) — more explicit, version-controlled in workflow file

### Updated Threshold (Per User Decision)

Change from 70/80/90 to 75% single threshold:
```r
# In .github/workflows/coverage-check.yml
MINIMUM_COVERAGE <- 75
# Remove WARNING_COVERAGE and TARGET_COVERAGE logic
# Change fail behavior to warn-only
```

**Warn-only implementation:**
```r
if (percent < MINIMUM_COVERAGE) {
  cat(sprintf("⚠️  Coverage (%.2f%%) is below target threshold (%.0f%%)\n", percent, MINIMUM_COVERAGE))
  # Don't quit with status 1 — just report
} else {
  cat(sprintf("✓ Coverage (%.2f%%) meets or exceeds target (%.0f%%)\n", percent, MINIMUM_COVERAGE))
}
# Never quit(status = 1) — coverage is informational only
```

## Open Questions

1. **Should max_pages be exposed in generated stubs?**
   - What we know: Currently hardcoded to 100 in generic_request default
   - What's unclear: Whether integration tests can verify max_pages behavior without modifying stubs
   - Recommendation: Add max_pages parameter to generated stub template (enhancement beyond phase scope, but document for future)

2. **How to handle mock complexity for httr2::req_perform_iterative?**
   - What we know: req_perform_iterative has complex signature with next_req callback
   - What's unclear: Whether mockery::stub can handle this effectively
   - Recommendation: Try stubbing req_perform_iterative first; if signature issues arise, mock at response level (httr2::resp_body_json)

3. **Should detection tests cover all 70 schema files?**
   - What we know: 70 schemas exist, but not all have pagination
   - What's unclear: Overhead of loading and parsing all schemas per test run
   - Recommendation: Load schemas once in test setup, cache in test environment; test representative sample (1-2 per registry pattern)

## Sources

### Primary (HIGH confidence)
- Project codebase: `dev/endpoint_eval/04_openapi_parser.R` (detect_pagination implementation)
- Project codebase: `R/z_generic_request.R` (pagination execution in generic_request lines 344-511)
- Project codebase: `dev/endpoint_eval/00_config.R` (PAGINATION_REGISTRY with 7 patterns)
- Project codebase: `.github/workflows/coverage-check.yml` (current coverage thresholds: 70/80/90)
- Project codebase: `tests/testthat/helper-vcr.R` (vcr configuration with API key filtering)
- Project codebase: `DESCRIPTION` (testthat >= 3.0.0, vcr in Suggests, parallel execution enabled)

### Secondary (MEDIUM confidence)
- testthat 3.0 documentation: https://testthat.r-lib.org/ (expect_* functions, test structure)
- vcr R package documentation: https://docs.ropensci.org/vcr/ (cassette recording patterns)
- covr R package documentation: https://covr.r-lib.org/ (coverage exclusion patterns)
- mockery R package: https://github.com/r-lib/mockery (stub() function for mocking)

### Tertiary (LOW confidence)
None — all research verified against project codebase or official R package documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages already in use or standard R testing tools
- Architecture: HIGH - Patterns follow existing test structure in project
- Pitfalls: HIGH - Identified from project-specific architecture (dev/ scripts, vcr setup, coverage config)

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (30 days - stable testing ecosystem)
