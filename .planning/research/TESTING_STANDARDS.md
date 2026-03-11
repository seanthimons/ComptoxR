# Features Research: R Package Testing Standards

**Domain:** R package schema parser/stub generator testing
**Researched:** 2026-01-29
**Confidence:** HIGH

---

## Executive Summary

Comprehensive R package testing for CRAN/rOpenSci submission requires achieving 75% test coverage with tests covering major functionality, error handling, and edge cases. For schema parsing code specifically, testing must validate JSON/OpenAPI parsing, reference resolution ($ref chains), version detection (Swagger 2.0 vs OpenAPI 3.x), and error conditions. The testthat framework provides snapshot testing for complex outputs, parameterized testing via patrick package, and fixtures for test data management.

ComptoxR's stub generation pipeline has unique testing needs:
- **Schema parsing edge cases**: Nested refs, circular refs, missing properties, version differences
- **Code generation validation**: Generated stubs must be syntactically valid R code
- **Multi-schema support**: Multiple OpenAPI versions and dialects (Swagger 2.0, OpenAPI 3.x)

---

## Table Stakes (MUST HAVE for CRAN/rOpenSci)

These features are **required** for CRAN acceptance and rOpenSci peer review.

| Feature | Why Required | Complexity | Implementation Notes |
|---------|--------------|------------|---------------------|
| **R CMD check passes (0 ERRORs, 0 WARNINGs)** | CRAN policy: packages with errors/warnings will not be accepted | Low | Use `devtools::check()` locally and on CI |
| **75% test coverage minimum** | rOpenSci policy: "Test coverage below 75% will require additional tests or explanation" | Medium | Use `covr::package_coverage()` to measure |
| **Tests for major functionality** | Both CRAN and rOpenSci require functional coverage | Medium | All exported functions need basic happy-path tests |
| **Error handling tests** | rOpenSci: "tests should also cover the behavior of the package in case of errors" | Medium | Use `expect_error()`, `expect_warning()` for validation |
| **Platform independence** | CRAN: "work across all major R platforms" (Windows, macOS, Linux) | Low | Avoid platform-specific paths; use `test_path()` |
| **Fast execution** | CRAN: "checking should take as little CPU time as possible" | Low | Keep tests under a few seconds each |
| **Isolated tests** | Tests must be self-contained with setup/teardown | Medium | Use `withr::local_*()` for state management |
| **testthat 3e framework** | Industry standard, required for modern R packages | Low | Already implemented in ComptoxR |

### Dependencies
- All table stakes features are **independent** and must be implemented for submission
- Coverage threshold depends on having comprehensive functional and error tests

---

## Differentiators (Comprehensive Testing)

Features that push coverage toward 80-90%+ and demonstrate testing excellence.

| Feature | Value Proposition | Complexity | Implementation Notes |
|---------|-------------------|------------|---------------------|
| **Snapshot testing for generated code** | Validates stub generation output without brittle string matching | Medium | Use `expect_snapshot_value()` with JSON style for tibbles, or `expect_snapshot()` for code text |
| **Parameterized tests for edge cases** | Test multiple schema variations (nested refs, missing properties, version differences) without duplication | Medium | Use `patrick::with_parameters_test_that()` for compact edge case coverage |
| **Fixture-based schema testing** | Store real-world OpenAPI schemas as fixtures to test against production patterns | Low | Use `tests/testthat/fixtures/schemas/` directory |
| **Reference resolution chain testing** | Validate $ref resolution with circular refs, deep nesting, missing refs | High | Critical for `resolve_schema_ref()` — test fallback chain behavior |
| **Schema version detection tests** | Ensure Swagger 2.0 vs OpenAPI 3.x detection handles edge cases | Medium | Test with malformed, minimal, and hybrid schemas |
| **Code generation syntax validation** | Verify generated stubs are parseable R code | Medium | Use `parse(text = generated_code)` in tests |
| **Body schema type classification** | Test `get_body_schema_type()` with all schema patterns (chemical_array, string_array, object_array, etc.) | Medium | Parameterized tests with example schemas |
| **Empty endpoint detection** | Validate `is_empty_post_endpoint()` correctly identifies POST endpoints with no input parameters | Low | Test matrix of query/path/body combinations |
| **Metadata extraction accuracy** | Test `param_metadata()` extracts examples, descriptions, defaults, enums correctly | Medium | Use fixtures with comprehensive parameter examples |
| **Unicode/special character handling** | Ensure parsers handle non-ASCII characters in OpenAPI specs | Low | Test with international API names/descriptions |

### Dependencies
- Snapshot testing requires testthat 3.0.0+
- Parameterized testing requires patrick package
- Fixture management works best with `test_path()` helper

---

## Anti-Patterns (Testing Patterns to AVOID)

Common mistakes that cause brittle tests, maintenance burden, or false confidence.

| Anti-Pattern | Why Bad | What to Do Instead |
|--------------|---------|-------------------|
| **100% coverage obsession** | "Going from 90% or 99% coverage to 100% is not always the best use of development time" (R Packages guide) | Focus on **meaningful** coverage: complex logic, error paths, edge cases. Skip trivial getters/setters. |
| **Testing implementation details** | Makes refactoring impossible; tests break when internal structure changes | Test **external interfaces** (function signatures, outputs) not internal helper calls |
| **Shared mutable state between tests** | Tests pass in isolation but fail together; debugging nightmare | Use `withr::local_*()` for cleanup; make tests hermetic |
| **File-scoped test setup** | Code outside `test_that()` creates hidden dependencies | Move setup **inside** test blocks or to `tests/testthat/setup.R` with explicit teardown |
| **Manual string matching for complex outputs** | Brittle; breaks on whitespace/formatting changes | Use **snapshot tests** (`expect_snapshot()`) for complex output validation |
| **Skipping tests with `skip_on_cran()` without CI** | Tests never run, giving false confidence | "tests should still run on continuous integration" — use `skip_on_cran()` only for API calls |
| **Using `source()` in test files** | Bypasses package infrastructure; inconsistent with production | Use `helper.R` for test utilities; reference package functions with `:::` for internals |
| **Writing to package directory in tests** | Violates CRAN policy; pollutes source tree | Use `withr::local_tempfile()` or `withr::local_tempdir()` for file creation |
| **Copy-paste test code with minor variations** | Hard to maintain; obscures what's being tested | Use **parameterized tests** (patrick) or helper functions to reduce duplication |
| **Testing deprecated functions extensively** | Wastes time on code you're removing | Mark deprecated functions with `lifecycle::deprecate_soft()` and minimal tests |

---

## Parser/Schema Testing Patterns

Specific patterns for testing JSON/OpenAPI schema parsing code.

### Pattern 1: Fixture-Based Schema Testing

**What:** Store real OpenAPI schema JSON files in `tests/testthat/fixtures/schemas/` and parse them in tests.

**When:** Testing against production API schemas or complex nested structures.

**Example:**
```r
test_that("openapi_to_spec parses real CompTox schema", {
  schema_file <- test_path("fixtures/schemas/ctx-hazard-prod.json")
  spec_json <- jsonlite::read_json(schema_file)

  result <- openapi_to_spec(spec_json, "ct_")

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_named(result, c("function_name", "endpoint", "method", ...))
})
```

**Why this works:** Real schemas expose edge cases synthetic examples miss. Fixtures are version-controlled and can be updated when APIs change.

---

### Pattern 2: Parameterized Edge Case Testing

**What:** Use patrick package to test multiple schema variations without code duplication.

**When:** Testing edge cases like missing properties, null values, different schema versions.

**Example:**
```r
library(patrick)

patrick::with_parameters_test_that(
  "resolve_schema_ref handles edge cases",
  {
    result <- resolve_schema_ref(schema, spec, fallback_chain)
    expect_type(result, expected_type)
  },
  .cases = tibble::tribble(
    ~.test_name,                ~schema,                     ~spec,     ~fallback_chain, ~expected_type,
    "nested ref",               list(`$ref` = "#/defs/X"),   nested_spec, NULL,          "list",
    "circular ref",             list(`$ref` = "#/defs/A"),   circular_spec, NULL,        "list",
    "missing ref with fallback", list(`$ref` = "#/missing"), base_spec, c("default"),   "list",
    "null schema",              NULL,                        base_spec, NULL,            "NULL"
  )
)
```

**Why this works:** Compact, readable, ensures consistent test structure across variations. Easier to add new cases than duplicating `test_that()` blocks.

---

### Pattern 3: Snapshot Testing for Generated Code

**What:** Use `expect_snapshot()` or `expect_snapshot_value()` to validate generated function stubs.

**When:** Testing code generation where exact string matching is too brittle, but you want to catch unintended changes.

**Example:**
```r
test_that("build_function_stub generates valid roxygen and code", {
  stub <- build_function_stub(
    fn = "ct_test_endpoint",
    endpoint = "/test/{id}",
    method = "POST",
    title = "Test Endpoint",
    config = ct_config
  )

  # Snapshot the generated code
  expect_snapshot(stub)

  # Verify it parses as valid R code
  expect_silent(parse(text = stub))
})
```

**On first run:** Creates `tests/testthat/_snaps/test-stub-generation.md` with recorded output.

**On subsequent runs:** Compares new output to snapshot; fails if changed (requiring review/update).

**Why this works:** Human-reviewable diffs, catches formatting regressions, doesn't break on intentional whitespace changes (after snapshot update).

---

### Pattern 4: Error Path Testing with `expect_error()`

**What:** Validate that parsers fail gracefully with informative messages.

**When:** Testing malformed schemas, missing required fields, version mismatches.

**Example:**
```r
test_that("detect_schema_version errors on missing version fields", {
  invalid_schema <- list(paths = list())  # No 'openapi' or 'swagger' field

  expect_error(
    detect_schema_version(invalid_schema),
    regexp = "Could not detect schema version",
    class = "validation_error"  # If using custom error classes
  )
})

test_that("resolve_schema_ref warns on unresolvable reference", {
  spec <- list(components = list(schemas = list()))
  schema <- list(`$ref` = "#/components/schemas/MissingSchema")

  expect_warning(
    resolve_schema_ref(schema, spec),
    regexp = "Could not resolve schema reference"
  )
})
```

**Why this works:** Ensures failures are debuggable. Users get helpful error messages, not cryptic stack traces.

---

### Pattern 5: Schema Type Classification Testing

**What:** Test `get_body_schema_type()` with comprehensive examples of each schema pattern.

**When:** Validating the type detection logic that drives code generation.

**Example:**
```r
test_that("get_body_schema_type classifies schema types correctly", {
  # Chemical array schema
  chemical_array_schema <- list(
    content = list(
      `application/json` = list(
        schema = list(`$ref` = "#/components/schemas/ChemicalRequest")
      )
    )
  )
  expect_equal(
    get_body_schema_type(chemical_array_schema, openapi_spec),
    "chemical_array"
  )

  # String array schema (e.g., SMILES)
  string_array_schema <- list(
    content = list(
      `application/json` = list(
        schema = list(type = "array", items = list(type = "string"))
      )
    )
  )
  expect_equal(
    get_body_schema_type(string_array_schema, openapi_spec),
    "string_array"
  )

  # Add more type classifications...
})
```

**Why this works:** Classification logic is critical—wrong type → wrong generated code. Comprehensive tests prevent regressions.

---

### Pattern 6: Reference Resolution Chain Testing

**What:** Test the fallback chain behavior in `resolve_schema_ref()`.

**When:** Validating complex $ref resolution with multiple fallback strategies.

**Example:**
```r
test_that("resolve_schema_ref follows fallback chain", {
  # Schema with primary ref that doesn't exist, but fallback does
  spec <- list(
    components = list(
      schemas = list(
        FallbackSchema = list(type = "object", properties = list(id = list(type = "string")))
      )
    )
  )

  schema <- list(`$ref` = "#/components/schemas/MissingPrimary")
  fallback_chain <- c("#/components/schemas/FallbackSchema")

  result <- resolve_schema_ref(schema, spec, fallback_chain)

  expect_type(result, "list")
  expect_equal(result$type, "object")
  expect_true("properties" %in% names(result))
})

test_that("resolve_schema_ref detects circular references", {
  # Circular ref: A -> B -> A
  spec <- list(
    components = list(
      schemas = list(
        SchemaA = list(`$ref` = "#/components/schemas/SchemaB"),
        SchemaB = list(`$ref` = "#/components/schemas/SchemaA")
      )
    )
  )

  schema <- list(`$ref` = "#/components/schemas/SchemaA")

  # Should detect circular ref and either error or return a safe default
  expect_error(
    resolve_schema_ref(schema, spec, max_depth = 10),
    regexp = "circular|recursion"
  )
})
```

**Why this works:** Reference resolution is the most complex part of schema parsing. Edge cases like circular refs can cause infinite loops if not handled.

---

### Pattern 7: Metadata Extraction Validation

**What:** Test `param_metadata()` extracts all parameter attributes correctly.

**When:** Validating that roxygen documentation will have accurate examples, defaults, and descriptions.

**Example:**
```r
test_that("param_metadata extracts all parameter attributes", {
  params <- list(
    list(
      name = "limit",
      in = "query",
      required = FALSE,
      schema = list(
        type = "integer",
        default = 100,
        enum = c(10, 50, 100, 500)
      ),
      description = "Maximum number of results"
    )
  )

  metadata <- param_metadata(params, where = "query")

  expect_length(metadata, 1)
  expect_equal(metadata$limit$name, "limit")
  expect_equal(metadata$limit$type, "integer")
  expect_equal(metadata$limit$default, 100)
  expect_equal(metadata$limit$enum, c(10, 50, 100, 500))
  expect_equal(metadata$limit$description, "Maximum number of results")
  expect_false(metadata$limit$required)
})
```

**Why this works:** Metadata drives roxygen documentation. Incorrect extraction → bad docs.

---

## Test Coverage Strategy

### Achieving 75%+ Coverage for Schema Parsers

**Focus areas for highest ROI:**

1. **Happy path coverage (30% of effort, 50% of coverage)**
   - Each exported function with valid input
   - Basic schema parsing with well-formed OpenAPI specs

2. **Error path coverage (40% of effort, 30% of coverage)**
   - Malformed JSON
   - Missing required fields
   - Invalid schema references
   - Version detection failures

3. **Edge case coverage (30% of effort, 20% of coverage)**
   - Nested/circular refs
   - Schema version hybrids (Swagger 2.0 with OpenAPI 3.x extensions)
   - Unicode/special characters
   - Empty/minimal schemas

**Functions to prioritize for ComptoxR stub pipeline:**

| Function | Coverage Priority | Rationale |
|----------|------------------|-----------|
| `openapi_to_spec()` | **HIGH** | Main entry point; errors here cascade everywhere |
| `resolve_schema_ref()` | **HIGH** | Complex logic; circular refs can cause infinite loops |
| `detect_schema_version()` | **MEDIUM** | Edge cases rare but version detection critical |
| `get_body_schema_type()` | **HIGH** | Classification drives code generation; wrong type = broken stubs |
| `is_empty_post_endpoint()` | **MEDIUM** | Logic-heavy; matrix of conditions to test |
| `extract_body_properties()` | **HIGH** | Complex schema traversal; many edge cases |
| `build_function_stub()` | **MEDIUM** | Code generation; validate syntax and structure |
| `param_metadata()` | **LOW** | Straightforward extraction; few edge cases |

**Coverage measurement:**
```r
# Run with coverage report
covr::package_coverage()

# Interactive coverage explorer (highlights uncovered lines)
covr::report()

# Check specific file coverage
covr::file_coverage("R/openapi_parser.R", "tests/testthat/test-openapi-parser.R")
```

---

## Test Organization

**Recommended structure for schema parser tests:**

```
tests/testthat/
├── fixtures/
│   ├── schemas/
│   │   ├── ctx-hazard-prod.json          # Real CompTox schema
│   │   ├── minimal-swagger-2.json        # Minimal valid Swagger 2.0
│   │   ├── minimal-openapi-3.json        # Minimal valid OpenAPI 3.0
│   │   ├── circular-refs.json            # Circular $ref test case
│   │   ├── nested-refs.json              # Deep nesting test case
│   │   └── malformed.json                # Invalid schema for error tests
│   └── expected-stubs/
│       └── ct_test_endpoint.R            # Expected output for snapshot comparison
├── helper-schemas.R                      # Schema fixture loading helpers
├── test-openapi-parser.R                 # Tests for openapi_to_spec()
├── test-schema-resolution.R              # Tests for resolve_schema_ref()
├── test-schema-version.R                 # Tests for detect_schema_version()
├── test-body-schema-type.R               # Tests for get_body_schema_type()
├── test-stub-generation.R                # Tests for build_function_stub()
└── test-empty-endpoint-detection.R       # Tests for is_empty_post_endpoint()
```

**Helper file example (`helper-schemas.R`):**
```r
# Load schema fixtures with consistent error handling
load_schema_fixture <- function(filename) {
  path <- test_path("fixtures", "schemas", filename)
  jsonlite::read_json(path)
}

# Common test schemas
minimal_swagger_2 <- function() {
  load_schema_fixture("minimal-swagger-2.json")
}

minimal_openapi_3 <- function() {
  load_schema_fixture("minimal-openapi-3.json")
}
```

---

## MVP Recommendation for Milestone

**For this milestone (test coverage for stub generation pipeline):**

### Phase 1: Table Stakes (Week 1)
1. Basic happy-path tests for all parser functions
2. Error handling tests for invalid schemas
3. Achieve 75% coverage baseline

### Phase 2: Edge Cases (Week 2)
4. Parameterized tests for schema variations
5. Reference resolution chain testing
6. Schema version detection edge cases

### Phase 3: Code Generation Validation (Week 3)
7. Snapshot testing for generated stubs
8. Syntax validation for generated code
9. Comprehensive body schema type classification tests

**Defer to post-MVP:**
- 90%+ coverage (diminishing returns)
- Performance benchmarking for large schemas
- Fuzzing/property-based testing with random schemas

---

## Continuous Integration Requirements

**CRAN/rOpenSci expect CI across platforms:**

```yaml
# .github/workflows/R-CMD-check.yaml
on: [push, pull_request]
jobs:
  R-CMD-check:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        r-version: ['release', 'devel']
```

**Test execution on CI:**
- All tests run (no `skip_on_ci()` for parser tests)
- Coverage report uploaded to Codecov/Coveralls
- Check passes with 0 ERRORs, 0 WARNINGs
- Coverage badge shows ≥75%

---

## Sources

### rOpenSci Requirements
- [rOpenSci Packaging Guide – Testing](https://devguide.ropensci.org/pkg_building.html) — PRIMARY SOURCE for rOpenSci testing requirements
- [rOpenSci Standards: Version 0.2.0](https://stats-devguide.ropensci.org/standards.html) — Statistical software peer review standards

### CRAN Requirements
- [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html) — Official CRAN submission policies
- [Checklist for CRAN Submissions](https://cran.r-project.org/web/packages/submission_checklist.html) — Pre-submission validation
- [22 Releasing to CRAN – R Packages (2e)](https://r-pkgs.org/release.html) — Comprehensive CRAN release guide

### Testing Best Practices
- [13 Testing Basics – R Packages (2e)](https://r-pkgs.org/testing-basics.html) — Foundational testing concepts
- [14 Designing Your Test Suite – R Packages (2e)](https://r-pkgs.org/testing-design.html) — PRIMARY SOURCE for test design patterns
- [Unit Testing for R • testthat](https://testthat.r-lib.org/) — Official testthat documentation
- [Package 'testthat' January 11, 2026](https://cran.r-project.org/web/packages/testthat/testthat.pdf) — Latest testthat reference manual

### Advanced Testing Techniques
- [Snapshot Tests • testthat](https://testthat.r-lib.org/articles/snapshotting.html) — Snapshot testing guide
- [GitHub - google/patrick: Parameterized Testing in R](https://github.com/google/patrick) — Parameterized test framework
- [Test Coverage for Packages • covr](https://covr.r-lib.org/) — Coverage measurement tools

### OpenAPI Testing Context
- [Schemathesis - Property-based API Testing](https://schemathesis.io/) — OpenAPI edge case testing inspiration (Python, but concepts apply)
- [Best Practices | OpenAPI Documentation](https://learn.openapis.org/best-practices.html) — OpenAPI schema design patterns
