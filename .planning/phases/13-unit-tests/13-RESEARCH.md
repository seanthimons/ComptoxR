# Phase 13: Unit Tests - Research

**Researched:** 2026-01-30
**Domain:** R package testing with testthat 3.x for internal pipeline functions
**Confidence:** HIGH

## Summary

Phase 13 focuses on achieving 80%+ test coverage for the `dev/endpoint_eval/` pipeline functions using testthat 3.3.2 (latest stable, January 2026). The pipeline code transforms OpenAPI/Swagger schemas into R function stubs, requiring tests for:

1. **Configuration helpers** (`00_config.R`) - Null coalescing, column defaults, constants
2. **Schema resolution** (`01_schema_resolution.R`) - Reference resolution with circular ref detection, version-aware fallback
3. **OpenAPI parsing** (`04_openapi_parser.R`) - Schema version detection, body property extraction, classification
4. **Stub generation** (`07_stub_generation.R`) - Empty endpoint detection, function stub building

The codebase already follows established patterns: helper-pipeline.R for shared infrastructure, minimal JSON fixtures for edge cases, and integration tests for Phase 14. User decisions constrain the approach: mirror pipeline files 1:1, use describe() blocks for grouping, snapshot-test generated code, and test in dependency order (01 → 04 → 07).

**Primary recommendation:** Follow the established helper-vcr.R pattern with global setup/cleanup, use minimal focused fixtures for edge cases (circular refs, malformed schemas, version mismatches), and leverage testthat 3.3's stable snapshot testing for generated code validation.

## Standard Stack

The established libraries/tools for R package testing in the ComptoxR ecosystem:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| testthat | 3.3.2 | Unit testing framework | De facto standard for R packages, edition 3 with stable snapshots |
| withr | latest | Temporary state management | Recommended by R Packages (2e), "free dependency" in tidyverse |
| jsonlite | 1.8.8+ | JSON fixture loading | Already imported, handles OpenAPI schema parsing |
| here | latest | Path construction | Already imported, cross-platform fixture paths |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| vcr | latest | HTTP cassette recording | API wrapper tests (Phase 14), not pipeline unit tests |
| covr | latest | Coverage reporting | CI/CD and local development, optional |
| cli | latest | Test output/warnings | Already imported, for custom expectations |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| testthat | tinytest | Lighter weight but requires `:::` for internal functions, no snapshot support |
| testthat | RUnit | Outdated, no modern BDD syntax, poor IDE integration |
| withr | manual cleanup | Error-prone, no automatic restore on test failure |

**Installation:**
```r
# Already in DESCRIPTION (Suggests)
# testthat >= 3.0.0
# withr
# No additional dependencies needed
```

## Architecture Patterns

### Recommended Project Structure
```
tests/testthat/
├── helper-pipeline.R              # Shared utilities (source_pipeline_files, clear_stubgen_env, get_fixture_path, load_fixture_schema)
├── test-pipeline-infrastructure.R # Infrastructure verification (Phase 12)
├── test-pipeline-config.R         # Tests for 00_config.R (Phase 13)
├── test-pipeline-schema-resolution.R # Tests for 01_schema_resolution.R (Phase 13)
├── test-pipeline-openapi-parser.R # Tests for 04_openapi_parser.R (Phase 13)
├── test-pipeline-stub-generation.R # Tests for 07_stub_generation.R (Phase 13)
└── fixtures/
    └── schemas/
        ├── minimal-openapi-3.json      # Basic valid OpenAPI 3.0
        ├── minimal-swagger-2.json      # Basic valid Swagger 2.0
        ├── circular-refs.json          # Circular reference edge case
        ├── malformed.json              # Invalid schema edge case
        └── [new fixtures per edge case]
```

### Pattern 1: Test File Organization (1:1 Mirroring)
**What:** Each pipeline file gets exactly one test file with the same conceptual name.
**When to use:** Always for pipeline unit tests (user decision from CONTEXT.md).
**Example:**
```r
# test-pipeline-config.R tests dev/endpoint_eval/00_config.R
# test-pipeline-schema-resolution.R tests dev/endpoint_eval/01_schema_resolution.R
```

### Pattern 2: Describe Blocks for Function Grouping
**What:** Use `describe("function_name", { ... })` to group tests by function, with nested `it()` or `test_that()` blocks.
**When to use:** Within each test file to organize tests by the function under test (user decision from CONTEXT.md).
**Example:**
```r
# Source: https://testthat.r-lib.org/reference/describe.html
describe("resolve_schema_ref", {
  test_that("resolves normal references", { ... })
  test_that("handles circular references", { ... })
  test_that("enforces depth limits", { ... })
})

describe("validate_schema_ref", {
  test_that("accepts valid references", { ... })
  test_that("rejects external file refs", { ... })
})
```

### Pattern 3: Global Helper Setup (Not Per-Test)
**What:** Use helper-pipeline.R for shared state management, not `withr::defer()` in each test.
**When to use:** Always (user decision from CONTEXT.md, matching helper-vcr.R pattern).
**Example:**
```r
# helper-pipeline.R (already exists)
source_pipeline_files <- function() { ... }  # Source all pipeline files
clear_stubgen_env <- function() { ... }      # Clean up .StubGenEnv state
get_fixture_path <- function(filename) { testthat::test_path("fixtures", "schemas", filename) }
load_fixture_schema <- function(filename) { jsonlite::fromJSON(get_fixture_path(filename), simplifyVector = FALSE) }

# In test files: call directly, no per-test cleanup
test_that("function works", {
  clear_stubgen_env()  # Explicit cleanup when needed
  schema <- load_fixture_schema("minimal-openapi-3.json")
  # ... test
})
```

### Pattern 4: Minimal Focused Fixtures
**What:** One fixture per edge case type, containing minimal valid schema to trigger that edge case.
**When to use:** Always (user decision from CONTEXT.md).
**Example:**
```json
// circular-refs.json - MINIMAL schema showing circular reference
{
  "openapi": "3.0.0",
  "info": {"title": "Circular Test", "version": "1.0"},
  "paths": {
    "/circular": {
      "post": {
        "requestBody": {
          "content": {"application/json": {"schema": {"$ref": "#/components/schemas/Node"}}}
        }
      }
    }
  },
  "components": {
    "schemas": {
      "Node": {
        "type": "object",
        "properties": {
          "value": {"type": "string"},
          "children": {"type": "array", "items": {"$ref": "#/components/schemas/Node"}}
        }
      }
    }
  }
}
```

### Pattern 5: Snapshot Testing for Generated Code
**What:** Use `expect_snapshot()` for function stub output, capturing signature + body structure.
**When to use:** Testing `build_function_stub()` and similar generation functions (user decision from CONTEXT.md).
**Example:**
```r
# Source: https://testthat.r-lib.org/articles/snapshotting.html
test_that("build_function_stub generates correct structure", {
  # Snapshot tests work by recording output to _snaps/{test}.md
  # First run creates snapshot, subsequent runs compare
  stub <- build_function_stub(
    fn = "test_function",
    endpoint = "/test/endpoint",
    method = "POST",
    # ... other params
  )

  # Capture key parts only (not full stub per user decision)
  expect_snapshot({
    cat("Function signature:\n")
    cat(stringr::str_extract(stub, "test_function <- function\\([^)]*\\)"))
    cat("\n\nBody structure:\n")
    cat(stringr::str_extract(stub, "generic_request\\([^)]*\\)"))
  })
})
```

### Pattern 6: Testing Internal Functions
**What:** testthat runs tests in the package namespace, so internal functions are accessible without `:::`.
**When to use:** Always for pipeline functions (all are internal/non-exported).
**Example:**
```r
# Source: https://github.com/r-lib/testthat/issues/1123
# Pipeline functions are not exported, but accessible in tests
test_that("resolve_schema_ref works", {
  # No need for ComptoxR:::resolve_schema_ref
  # Function is available because tests run in package namespace
  result <- resolve_schema_ref("#/components/schemas/Test", components, schema_version)
  expect_type(result, "list")
})
```

### Pattern 7: Representative Edge Case Sampling
**What:** One test per edge case type (missing field, null value, wrong type), not exhaustive permutations.
**When to use:** Always (user decision from CONTEXT.md).
**Example:**
```r
describe("ensure_cols", {
  test_that("handles missing columns", {
    df <- data.frame(a = 1:3)
    result <- ensure_cols(df, list(b = "default"))
    expect_true("b" %in% names(result))
  })

  test_that("handles empty data frame", {
    df <- data.frame()
    result <- ensure_cols(df, list(a = 1))
    expect_equal(nrow(result), 0)
  })

  # Don't test every possible column type - representative sample only
})
```

### Pattern 8: Dry-Run Testing (From Existing Codebase)
**What:** Use `Sys.setenv(run_debug = "TRUE")` to test request construction without network calls.
**When to use:** Testing generic_request logic (established pattern in test-generic_request.R).
**Example:**
```r
# Source: test-generic_request.R (existing codebase)
test_that("function builds correct request", {
  Sys.setenv(run_debug = "TRUE")
  on.exit(Sys.setenv(run_debug = "FALSE"))

  output <- capture_output(
    result <- generic_request(query = "test", endpoint = "endpoint")
  )

  expect_match(output, "POST /endpoint")
})
```

### Anti-Patterns to Avoid
- **Per-test withr::defer():** Use global helper cleanup instead (user decision)
- **Exhaustive edge case matrices:** Representative samples only (user decision)
- **Testing downstream symptoms:** Test at the source (01 → 04 → 07 order) (user decision)
- **Large kitchen-sink fixtures:** Minimal focused fixtures per edge case (user decision)
- **Snapshot entire function stubs:** Capture key parts only (user decision)

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Temporary state management | Manual setup/teardown with on.exit() | withr package (withr::local_*) | Automatic restore on error, cleaner syntax, R Packages (2e) recommended |
| Snapshot testing | Manual file comparison | expect_snapshot() in testthat 3.3+ | Built-in diff, git integration, variant support, now stable |
| Test organization | Flat test_that() list | describe() blocks | Self-documenting, easier navigation, variable scoping |
| JSON fixture loading | readLines() + jsonlite | Helper function (load_fixture_schema) | Already implemented, consistent paths |
| Testing internal functions | Package:::function | Direct call in test | testthat runs in package namespace, no ::: needed |
| Coverage reporting | Manual tracking | covr::package_coverage() | Standard tool, IDE integration, zero_coverage() for gaps |

**Key insight:** testthat 3.x (2021+) moved snapshot testing from experimental to stable, making it the standard approach for testing generated code. Don't implement custom file comparison logic.

## Common Pitfalls

### Pitfall 1: Snapshot Tests Fail on CRAN
**What goes wrong:** Snapshot tests are not verified on CRAN by default, causing false confidence in CI.
**Why it happens:** Snapshots require human review and are fragile to minor dependency changes.
**How to avoid:** Don't rely solely on snapshots for correctness validation. Combine with assertions.
**Warning signs:** Tests pass locally but CRAN checks fail due to missing snapshot verification.
```r
# Source: https://testthat.r-lib.org/articles/snapshotting.html
# DON'T rely only on snapshots
test_that("function generates stub", {
  stub <- build_function_stub(...)
  expect_snapshot(stub)  # CRAN won't verify this
})

# DO combine snapshot with assertions
test_that("function generates stub", {
  stub <- build_function_stub(...)
  expect_type(stub, "character")         # Assertion: always verified
  expect_true(grepl("function\\(", stub)) # Assertion: structural check
  expect_snapshot(stub)                   # Snapshot: for human review
})
```

### Pitfall 2: Testing Non-Exported Functions with `:::`
**What goes wrong:** Using `:::` in tests is unnecessary and creates maintenance burden.
**Why it happens:** Misunderstanding how testthat runs tests (it uses package namespace).
**How to avoid:** Call internal functions directly in tests without `:::`.
**Warning signs:** `PackageName:::function_name` appearing in test files.
```r
# Source: https://github.com/r-lib/testthat/issues/1123
# WRONG - unnecessary and verbose
result <- ComptoxR:::resolve_schema_ref(ref, components)

# RIGHT - direct call works because tests run in package namespace
result <- resolve_schema_ref(ref, components)
```

### Pitfall 3: Circular Reference Tests Hang Indefinitely
**What goes wrong:** Testing circular reference handling without depth limits causes infinite recursion.
**Why it happens:** Recursive schema resolution without max_depth enforcement.
**How to avoid:** Verify "no error" for circular refs, don't test depth boundaries (user decision from CONTEXT.md).
**Warning signs:** Test suite hangs, R session crashes with stack overflow.
```r
# DON'T test exact depth or try to trigger overflow
test_that("circular refs fail at exact depth", {
  # This could hang if implementation changes
  expect_error(resolve_schema_ref(..., max_depth = 100))
})

# DO test simple pass/fail behavior
test_that("circular refs are detected", {
  schema <- load_fixture_schema("circular-refs.json")
  # Verify no infinite loop - function should return or warn
  expect_no_error({
    result <- resolve_schema_ref("#/components/schemas/Node", schema$components)
  })
  # Or verify it returns a sentinel value
  expect_equal(result$type, "circular_ref")
})
```

### Pitfall 4: Ignoring Swagger 2.0 vs OpenAPI 3.0 Differences
**What goes wrong:** Tests only use OpenAPI 3.0 fixtures, missing Swagger 2.0 edge cases.
**Why it happens:** OpenAPI 3.0 is newer and more common, but codebase supports both.
**How to avoid:** Separate fixtures for each version, test version detection explicitly (user decision from CONTEXT.md).
**Warning signs:** Functions fail on Swagger 2.0 schemas in production despite passing tests.
```r
# Source: dev/endpoint_eval/01_schema_resolution.R lines 169-182
# Pipeline has version-aware fallback: Swagger uses #/definitions/, OpenAPI uses #/components/schemas/

# DON'T assume OpenAPI 3.0 only
test_that("schema resolution works", {
  schema <- load_fixture_schema("minimal-openapi-3.json")  # Only tests one version
  result <- resolve_schema_ref("#/components/schemas/Test", schema)
})

# DO test both versions explicitly
describe("resolve_schema_ref", {
  test_that("resolves OpenAPI 3.0 references", {
    schema <- load_fixture_schema("minimal-openapi-3.json")
    version <- detect_schema_version(schema)
    result <- resolve_schema_ref("#/components/schemas/Test", schema$components, version)
    expect_type(result, "list")
  })

  test_that("resolves Swagger 2.0 references", {
    schema <- load_fixture_schema("minimal-swagger-2.json")
    version <- detect_schema_version(schema)
    result <- resolve_schema_ref("#/definitions/Test", schema$definitions, version)
    expect_type(result, "list")
  })
})
```

### Pitfall 5: 80% Coverage as Hard Requirement
**What goes wrong:** Chasing 80% coverage leads to low-value tests (testing trivial getters, constants).
**Why it happens:** Misunderstanding coverage as quality metric rather than guideline.
**How to avoid:** 80% is a guideline (user decision from CONTEXT.md). Focus on high-value tests first.
**Warning signs:** Tests for `CHEMICAL_SCHEMA_PATTERNS <- c(...)` or trivial one-liners.
```r
# Source: https://r-pkgs.org/testing-design.html
# Coverage is an "indirect measure of test quality"

# DON'T write tests just to hit 80%
test_that("constant is defined", {
  expect_true(length(CHEMICAL_SCHEMA_PATTERNS) > 0)  # Low value
})

# DO focus on behavior and edge cases
test_that("%||% handles NULL and NA correctly", {
  expect_equal(NULL %||% "default", "default")
  expect_equal(NA %||% "default", "default")
  expect_equal("value" %||% "default", "value")
  expect_equal(c(1, 2) %||% "default", c(1, 2))  # Non-scalar edge case
})
```

### Pitfall 6: Not Cleaning Up .StubGenEnv State
**What goes wrong:** Tests pass individually but fail when run together due to shared state pollution.
**Why it happens:** .StubGenEnv persists across tests, accumulating stale data.
**How to avoid:** Call clear_stubgen_env() at start of tests that modify .StubGenEnv.
**Warning signs:** `testthat::test_file()` passes, `devtools::test()` fails; random failures.
```r
# Source: helper-pipeline.R lines 51-57
# .StubGenEnv is a global environment for tracking skipped/suspicious endpoints

# WRONG - no cleanup
test_that("stub generation tracks skipped endpoints", {
  build_function_stub(...)  # Modifies .StubGenEnv$skipped
  expect_true(length(.StubGenEnv$skipped) > 0)
})
# Next test inherits .StubGenEnv$skipped from previous test!

# RIGHT - explicit cleanup
test_that("stub generation tracks skipped endpoints", {
  clear_stubgen_env()  # Start with clean state
  build_function_stub(...)
  expect_true(length(.StubGenEnv$skipped) > 0)
})
```

## Code Examples

Verified patterns from testthat 3.3.2 and existing codebase:

### Testing Helper Functions with Edge Cases
```r
# Source: dev/endpoint_eval/00_config.R lines 17-21
# Testing %||% null coalesce operator

describe("%||%", {
  test_that("returns right side for NULL", {
    expect_equal(NULL %||% "default", "default")
  })

  test_that("returns right side for single NA", {
    expect_equal(NA %||% "default", "default")
  })

  test_that("returns left side for non-NULL non-NA values", {
    expect_equal("value" %||% "default", "value")
    expect_equal(0 %||% "default", 0)
    expect_equal(FALSE %||% "default", FALSE)
  })

  test_that("handles vectors", {
    expect_equal(c(1, 2, 3) %||% "default", c(1, 2, 3))
  })
})
```

### Testing Schema Resolution with Fixtures
```r
# Source: helper-pipeline.R, test-pipeline-infrastructure.R
# Pattern: Load fixture, call function, verify behavior

describe("resolve_schema_ref", {
  # Setup: source pipeline files once per describe block
  source_pipeline_files()

  test_that("resolves normal OpenAPI 3.0 references", {
    schema <- load_fixture_schema("minimal-openapi-3.json")
    version <- detect_schema_version(schema)

    # Assume fixture has a schema to resolve
    result <- resolve_schema_ref(
      "#/components/schemas/TestSchema",
      schema$components,
      version
    )

    expect_type(result, "list")
    expect_false(is.null(result$type) && is.null(result$properties))
  })

  test_that("handles circular references without infinite loop", {
    clear_stubgen_env()
    schema <- load_fixture_schema("circular-refs.json")
    version <- detect_schema_version(schema)

    # Should return sentinel or warn, not hang
    expect_no_error({
      result <- resolve_schema_ref(
        "#/components/schemas/Node",
        schema$components,
        version,
        max_depth = 3
      )
    })
  })

  test_that("version-aware fallback works for Swagger 2.0", {
    schema <- load_fixture_schema("minimal-swagger-2.json")
    version <- detect_schema_version(schema)
    expect_equal(version$type, "swagger")

    # Swagger 2.0 uses #/definitions/ not #/components/schemas/
    # Function should fall back correctly
    result <- resolve_schema_ref(
      "#/definitions/TestDef",
      schema$definitions,
      version
    )

    expect_type(result, "list")
  })
})
```

### Testing with Expect Snapshot
```r
# Source: https://testthat.r-lib.org/reference/expect_snapshot.html
# Pattern: Generate output, capture key parts, verify structure

test_that("build_function_stub generates correct roxygen docs", {
  source_pipeline_files()
  clear_stubgen_env()

  stub <- build_function_stub(
    fn = "test_endpoint",
    endpoint = "/test/endpoint",
    method = "POST",
    title = "Test Endpoint Function",
    batch_limit = 200,
    path_param_info = list(primary = NULL, additional = character(0)),
    query_param_info = list(names = character(0), metadata = list()),
    body_param_info = list(type = "string_array", properties = list()),
    content_type = "application/json",
    config = list(),
    needs_resolver = FALSE,
    body_schema_type = "string_array",
    deprecated = FALSE,
    response_schema_type = "array",
    request_type = "json"
  )

  expect_type(stub, "character")

  # Snapshot only key parts (user decision from CONTEXT.md)
  expect_snapshot({
    cat("Function signature:\n")
    cat(stringr::str_extract(stub, "test_endpoint <- function\\([^)]+\\)"))

    cat("\n\nRoxygen title:\n")
    cat(stringr::str_extract(stub, "#' Test Endpoint Function"))

    cat("\n\nGeneric request call:\n")
    cat(stringr::str_extract(stub, "generic_request\\([^)]+\\)"))
  })
})
```

### Testing Empty Endpoint Detection
```r
# Source: dev/endpoint_eval/07_stub_generation.R lines 32-131
# Pattern: Test detection logic with different parameter combinations

describe("is_empty_post_endpoint", {
  test_that("returns skip=FALSE for GET requests", {
    result <- is_empty_post_endpoint(
      method = "GET",
      query_params = "",
      path_params = "",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_false(result$skip)
  })

  test_that("returns skip=TRUE for POST with no params and empty body", {
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "",
      path_params = "",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_true(result$skip)
    expect_match(result$reason, "No query params")
  })

  test_that("returns skip=FALSE if POST has query params", {
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "param1,param2",
      path_params = "",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_false(result$skip)
  })

  test_that("detects suspicious endpoints with only optional params", {
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "optional_param",
      path_params = "",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_false(result$skip)
    expect_true(result$suspicious)
  })
})
```

### Testing Error Handling and Validation
```r
# Source: https://testthat.r-lib.org/reference/expect_error.html
# Pattern: Test that invalid input triggers expected errors

describe("validate_schema_ref", {
  test_that("accepts valid internal references", {
    expect_true(validate_schema_ref("#/components/schemas/Test"))
    expect_true(validate_schema_ref("#/definitions/Test"))
  })

  test_that("rejects empty references", {
    expect_error(
      validate_schema_ref(""),
      "Invalid schema reference"
    )
  })

  test_that("rejects external file references", {
    expect_error(
      validate_schema_ref("external.json#/schemas/Test"),
      "External file reference not supported"
    )
  })

  test_that("rejects non-string references", {
    expect_error(
      validate_schema_ref(NULL),
      "empty or non-character"
    )
  })
})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| testthat 2.x context() blocks | testthat 3.x describe() blocks | testthat 3.0 (2020) | Better nesting, BDD-style, variable scoping |
| Manual file snapshots | expect_snapshot() | testthat 3.0-3.1 (2020-2021) | Stable snapshot testing, git integration, variants |
| expect_match() for complex output | expect_snapshot() | testthat 3.1+ (2021) | Human-readable diffs, easier review in PRs |
| Manual state cleanup | withr::local_*() functions | withr 2.0+ (2020) | Automatic restore on error, cleaner syntax |
| Flat test organization | describe() + nested test_that() | testthat 3.0+ (2020) | Self-documenting structure, easier navigation |

**Deprecated/outdated:**
- **context():** Replaced by describe() in testthat 3.0 - still works but discouraged for new code
- **Manual snapshot comparison:** expect_snapshot_file() without wrappers - fragile across platforms
- **expect_known_output():** Deprecated in favor of expect_snapshot() - removed in testthat 3.0
- **Skip helpers without reason:** skip() now requires explicit message - improves documentation

## Open Questions

Things that couldn't be fully resolved:

1. **R-specific JSON schema validators**
   - What we know: JavaScript (openapi-schema-validator), Python (openapi-schema-validator), Ruby (JSONSchemer) have mature validators
   - What's unclear: No R-native JSON Schema validator for OpenAPI 3.0/3.1 found in search results
   - Recommendation: Use fixture-based approach (existing pattern) rather than schema validation library. ComptoxR already parses schemas successfully, tests verify behavior not schema validity.

2. **Optimal coverage threshold for pipeline code**
   - What we know: 80% guideline from user decision, R Packages (2e) says coverage is "indirect measure"
   - What's unclear: No authoritative source recommends 80% specifically; varies by project
   - Recommendation: Follow user guideline (80%) but prioritize high-value tests (edge cases, error paths) over hitting exact percentage. Use covr::zero_coverage() to find untested critical paths.

3. **Snapshot test maintenance burden**
   - What we know: Snapshots are stable in testthat 3.3.2, but fragile to dependency changes (not verified on CRAN)
   - What's unclear: Long-term maintenance cost for snapshot tests in pipeline code (generated stubs change frequently during development?)
   - Recommendation: Use snapshots as supplement to assertions (not replacement). Capture key parts only per user decision. If stubs change frequently, consider structural assertions instead.

## Sources

### Primary (HIGH confidence)
- [Snapshot tests • testthat](https://testthat.r-lib.org/articles/snapshotting.html) - Official snapshot testing guide
- [Snapshot testing — expect_snapshot • testthat](https://testthat.r-lib.org/reference/expect_snapshot.html) - API reference
- [Package 'testthat' January 11, 2026 (v3.3.2)](https://cran.r-project.org/web/packages/testthat/testthat.pdf) - Current CRAN package
- [describe: a BDD testing language — describe • testthat](https://testthat.r-lib.org/reference/describe.html) - Describe block documentation
- [Test fixtures • testthat](https://testthat.r-lib.org/articles/test-fixtures.html) - Fixture organization patterns
- [Special files • testthat](https://testthat.r-lib.org/articles/special-files.html) - Helper file conventions
- [14 Designing your test suite – R Packages (2e)](https://r-pkgs.org/testing-design.html) - Testing best practices
- [13 Testing basics – R Packages (2e)](https://r-pkgs.org/testing-basics.html) - testthat fundamentals
- [Run Code With Temporarily Modified Global State • withr](https://withr.r-lib.org/) - withr official docs
- [Test Coverage for Packages • covr](https://covr.r-lib.org/) - Coverage reporting
- [Do you expect an error, warning, message, or other condition? — expect_error • testthat](https://testthat.r-lib.org/reference/expect_error.html) - Error testing patterns
- [Do you expect NULL? — expect_null • testthat](https://testthat.r-lib.org/reference/expect_null.html) - NULL testing

### Secondary (MEDIUM confidence)
- [R some blog: Nested unit tests with testthat](https://rpahl.github.io/r-some-blog/posts/2024-10-07-nested-unit-tests-with-testthat/) - Nested describe() patterns (2024)
- [Introduction to Snapshot Testing in R](https://indrajeetpatil.github.io/intro-to-snapshot-testing/) - Snapshot testing tutorial
- [Testing if a function has been exported · Issue #1123 · r-lib/testthat](https://github.com/r-lib/testthat/issues/1123) - Internal function testing clarification
- [Helper code and files for your testthat tests | R-bloggers](https://www.r-bloggers.com/2020/11/helper-code-and-files-for-your-testthat-tests/) - Helper file patterns (2020)

### Tertiary (LOW confidence)
- [Validating OpenAPI and JSON Schema](https://json-schema.org/blog/posts/validating-openapi-and-json-schema) - No R-specific tools mentioned
- WebSearch results for JSON schema validation - No R package found, ecosystem uses JS/Python tools

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - testthat 3.3.2 and withr are well-documented, stable, and already in DESCRIPTION
- Architecture: HIGH - Patterns verified from official docs (testthat, R Packages 2e) and existing codebase (helper-pipeline.R, test-generic_request.R)
- Pitfalls: HIGH - Documented in official testthat docs (snapshot CRAN behavior, internal function access) and validated against existing code patterns
- Code examples: HIGH - Derived from official testthat reference, existing test-pipeline-infrastructure.R, and pipeline source code

**Research date:** 2026-01-30
**Valid until:** 2026-03-30 (60 days - testthat is stable, slow-moving ecosystem)
