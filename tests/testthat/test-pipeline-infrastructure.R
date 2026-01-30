# Test that pipeline infrastructure works correctly

test_that("helper-pipeline.R loads successfully", {
  # Source the helper (should already be loaded by testthat)
  expect_true(exists("source_pipeline_files"))
  expect_true(exists("clear_stubgen_env"))
  expect_true(exists("get_fixture_path"))
  expect_true(exists("load_fixture_schema"))
})

test_that("pipeline files can be sourced in order", {
  skip_on_cran()  # Pipeline tests are for development, not CRAN

  # Clear any existing state
  clear_stubgen_env()

  # Source all pipeline files
  result <- source_pipeline_files()
  expect_true(result)

  # Key functions should exist after sourcing
  expect_true(exists("openapi_to_spec"))
  expect_true(exists("resolve_schema_ref"))
  expect_true(exists("detect_schema_version"))
  expect_true(exists("extract_body_properties"))

  # Clean up
  clear_stubgen_env()
})

test_that("fixtures load correctly", {
  skip_on_cran()

  # OpenAPI 3.0
  schema <- load_fixture_schema("minimal-openapi-3.json")
  expect_true(!is.null(schema$openapi))
  expect_equal(schema$openapi, "3.0.0")

  # Swagger 2.0
  schema2 <- load_fixture_schema("minimal-swagger-2.json")
  expect_true(!is.null(schema2$swagger))
  expect_equal(schema2$swagger, "2.0")

  # Circular refs (should load without error)
  schema3 <- load_fixture_schema("circular-refs.json")
  expect_true(!is.null(schema3$components$schemas$Node))

  # Malformed (valid JSON, invalid schema)
  schema4 <- load_fixture_schema("malformed.json")
  expect_true(is.null(schema4$openapi))
  expect_true(is.null(schema4$swagger))
})

test_that("clear_stubgen_env() cleans up state", {
  skip_on_cran()

  # Create some state
  if (!exists(".StubGenEnv", envir = .GlobalEnv)) {
    assign(".StubGenEnv", new.env(), envir = .GlobalEnv)
  }
  .StubGenEnv$test_var <- "test_value"

  # Clear it
  result <- clear_stubgen_env()
  expect_true(result)

  # Verify cleanup - either env removed or emptied
  if (exists(".StubGenEnv", envir = .GlobalEnv)) {
    expect_equal(length(ls(.StubGenEnv)), 0)
  }
})

test_that("withr is available for state management", {
  skip_on_cran()
  expect_true(requireNamespace("withr", quietly = TRUE))
})
