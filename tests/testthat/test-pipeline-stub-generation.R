# Tests for Stub Generation Functions (07_stub_generation.R)
# These functions generate R function code from endpoint specifications

skip_on_cran()

# ==============================================================================
# Helper Operator Tests
# ==============================================================================

describe("%|NA|%", {
  test_that("returns default for NULL", {
    source_pipeline_files()
    result <- NULL %|NA|% "default"
    expect_equal(result, "default")
  })

  test_that("returns default for NA", {
    source_pipeline_files()
    result <- NA %|NA|% "default"
    expect_equal(result, "default")
  })

  test_that("returns value for non-NULL non-NA", {
    source_pipeline_files()
    expect_equal("value" %|NA|% "default", "value")
    expect_equal(0 %|NA|% "default", 0)
    expect_equal(FALSE %|NA|% "default", FALSE)
  })

  test_that("handles vectors", {
    source_pipeline_files()
    result <- c(1, 2, 3) %|NA|% "default"
    expect_equal(result, c(1, 2, 3))
  })
})

# ==============================================================================
# Empty Endpoint Detection Tests
# ==============================================================================

describe("is_empty_post_endpoint", {
  test_that("returns skip=FALSE for GET requests", {
    source_pipeline_files()
    result <- is_empty_post_endpoint(
      method = "GET",
      query_params = "",
      path_params = "",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_false(result$skip)
    expect_equal(result$reason, "")
  })

  test_that("returns skip=TRUE for POST with no params and empty body", {
    source_pipeline_files()
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
    source_pipeline_files()
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "param1,param2",
      path_params = "",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_false(result$skip)
  })

  test_that("returns skip=FALSE if POST has path params", {
    source_pipeline_files()
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "",
      path_params = "id,name",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_false(result$skip)
  })

  test_that("returns skip=FALSE if POST has body with properties", {
    source_pipeline_files()
    body_schema <- list(
      type = "object",
      properties = list(
        field1 = list(type = "string"),
        field2 = list(type = "integer")
      )
    )
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "",
      path_params = "",
      body_schema_full = body_schema,
      body_schema_type = "object"
    )
    expect_false(result$skip)
  })

  test_that("detects suspicious endpoints with query params but empty body", {
    source_pipeline_files()
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "optional_param",
      path_params = "",
      body_schema_full = NULL,
      body_schema_type = "unknown"
    )
    expect_false(result$skip)
    expect_true(result$suspicious)
    expect_match(result$suspicious_reason, "Only query parameters")
  })

  test_that("returns correct reason string when skipping", {
    source_pipeline_files()
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "",
      path_params = "",
      body_schema_full = list(),
      body_schema_type = "unknown"
    )
    expect_true(result$skip)
    expect_true(nzchar(result$reason))
    expect_match(result$reason, "No query params.*no path params")
  })

  test_that("handles object with empty properties", {
    source_pipeline_files()
    body_schema <- list(
      type = "object",
      properties = list()  # Empty properties
    )
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "",
      path_params = "",
      body_schema_full = body_schema,
      body_schema_type = "object"
    )
    expect_true(result$skip)
    expect_match(result$reason, "object with no properties")
  })

  test_that("handles array of primitives", {
    source_pipeline_files()
    body_schema <- list(
      type = "array",
      items = list(type = "string")
    )
    result <- is_empty_post_endpoint(
      method = "POST",
      query_params = "",
      path_params = "",
      body_schema_full = body_schema,
      body_schema_type = "string_array"
    )
    expect_true(result$skip)
    expect_match(result$reason, "array of string")
  })
})

# ==============================================================================
# Function Stub Generation Tests
# ==============================================================================

# Helper function to provide sensible defaults for build_function_stub
create_stub_defaults <- function() {
  list(
    fn = "test_function",
    endpoint = "/test/endpoint",
    method = "GET",
    title = "Test Function",
    batch_limit = 1,
    path_param_info = list(
      has_path_params = FALSE,
      has_any_path_params = FALSE,
      primary_param = NULL,
      fn_signature = "",
      param_docs = "",
      path_params_call = "",
      primary_example = NA
    ),
    query_param_info = list(
      has_params = FALSE,
      primary_param = NULL,
      fn_signature = "",
      param_docs = "",
      params_call = "",
      params_code = "",
      primary_example = NA
    ),
    body_param_info = list(
      has_params = FALSE,
      primary_param = NULL,
      fn_signature = "",
      param_docs = "",
      primary_example = NA
    ),
    content_type = "application/json",
    config = list(
      wrapper_function = "generic_request",
      example_query = "DTXSID7020182",
      lifecycle_badge = "experimental"
    ),
    needs_resolver = FALSE,
    body_schema_type = "unknown",
    deprecated = FALSE,
    response_schema_type = "object",
    request_type = "query_only"
  )
}

describe("build_function_stub", {
  test_that("generates function with correct signature", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$path_param_info$has_path_params <- TRUE
    defaults$path_param_info$has_any_path_params <- TRUE
    defaults$path_param_info$primary_param <- "dtxsid"
    defaults$path_param_info$fn_signature <- "dtxsid"
    defaults$path_param_info$param_docs <- "#' @param dtxsid Chemical identifier\n"

    stub <- do.call(build_function_stub, defaults)

    expect_type(stub, "character")
    expect_true(grepl("test_function <- function\\(dtxsid\\)", stub))
  })

  test_that("includes roxygen documentation with title", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl("#' Test Function", stub))
    expect_true(grepl("#' @export", stub))
    expect_true(grepl("#' @return", stub))
  })

  test_that("includes lifecycle badge", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl("lifecycle::badge\\(\"experimental\"\\)", stub))
  })

  test_that("handles deprecated endpoints", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$deprecated <- TRUE
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl("lifecycle::badge\\(\"deprecated\"\\)", stub))
  })

  test_that("generates generic_request() call for standard endpoints", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$config$wrapper_function <- "generic_request"
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl("generic_request\\(", stub))
  })

  test_that("generates generic_chemi_request() call for chemi endpoints", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$config$wrapper_function <- "generic_chemi_request"
    defaults$request_type <- "json"
    defaults$body_param_info$has_params <- TRUE
    defaults$body_param_info$primary_param <- "query"
    defaults$body_param_info$fn_signature <- "query"
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl("generic_chemi_request\\(", stub))
  })

  test_that("snapshot test - simple GET endpoint", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$method <- "GET"
    defaults$batch_limit <- 0
    defaults$request_type <- "query_only"
    stub <- do.call(build_function_stub, defaults)

    expect_type(stub, "character")
    expect_true(grepl("test_function <- function", stub))

    # Snapshot key parts only (per CONTEXT.md decision)
    expect_snapshot({
      cat("Function signature:\n")
      signature <- stringr::str_extract(stub, "test_function <- function\\([^)]*\\)")
      cat(signature)

      cat("\n\nGeneric request call:\n")
      request_call <- stringr::str_extract(stub, "generic_request\\([^}]+endpoint")
      cat(request_call)
    })
  })

  test_that("snapshot test - POST with body params", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$method <- "POST"
    defaults$request_type <- "json"
    defaults$body_param_info$has_params <- TRUE
    defaults$body_param_info$primary_param <- "data"
    defaults$body_param_info$fn_signature <- "data, optional = NULL"
    defaults$body_param_info$param_docs <- "#' @param data Input data\n#' @param optional Optional parameter\n"
    defaults$body_schema_type <- "simple_object"
    stub <- do.call(build_function_stub, defaults)

    expect_type(stub, "character")
    expect_true(grepl("function\\(data, optional = NULL\\)", stub))

    # Snapshot key parts
    expect_snapshot({
      cat("Function signature:\n")
      signature <- stringr::str_extract(stub, "test_function <- function\\([^)]+\\)")
      cat(signature)

      cat("\n\nBody building:\n")
      body_code <- stringr::str_extract(stub, "# Build request body[^}]+body \\<- list\\(\\)")
      if (!is.na(body_code)) cat(body_code)
    })
  })

  test_that("snapshot test - endpoint with path parameters", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$request_type <- "path"
    defaults$path_param_info$has_path_params <- TRUE
    defaults$path_param_info$has_any_path_params <- TRUE
    defaults$path_param_info$primary_param <- "id"
    defaults$path_param_info$fn_signature <- "id"
    defaults$path_param_info$param_docs <- "#' @param id Identifier\n"
    defaults$path_param_info$path_params_call <- ",\n    path_params = c(id = id)"
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl("function\\(id\\)", stub))
    expect_true(grepl("path_params = c\\(id = id\\)", stub))

    # Snapshot
    expect_snapshot({
      cat("Path parameter handling:\n")
      path_code <- stringr::str_extract(stub, "path_params = c\\([^)]+\\)")
      cat(path_code)
    })
  })

  test_that("handles simple body types correctly", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$method <- "POST"
    defaults$request_type <- "json"
    defaults$body_schema_type <- "string_array"
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl("function\\(query\\)", stub))
    expect_true(grepl("query = query", stub))
  })

  test_that("handles raw text body endpoints", {
    source_pipeline_files()
    clear_stubgen_env()

    defaults <- create_stub_defaults()
    defaults$endpoint <- "chemical/search/equal/"
    defaults$method <- "POST"
    defaults$body_schema_type <- "string"
    stub <- do.call(build_function_stub, defaults)

    expect_true(grepl('body_type = "raw_text"', stub))
  })
})

# ==============================================================================
# Environment Tracking Tests
# ==============================================================================

describe("reset_endpoint_tracking", {
  test_that("clears .StubGenEnv$skipped", {
    source_pipeline_files()

    # Populate environment
    .StubGenEnv$skipped <- list(data.frame(route = "/test", method = "POST"))
    .StubGenEnv$suspicious <- list(data.frame(route = "/test2", method = "GET"))

    # Reset
    reset_endpoint_tracking()

    # Verify cleared
    expect_equal(length(.StubGenEnv$skipped), 0)
    expect_equal(length(.StubGenEnv$suspicious), 0)
  })

  test_that("handles empty environment", {
    source_pipeline_files()
    clear_stubgen_env()

    # Should not error on empty env
    expect_no_error(reset_endpoint_tracking())
  })
})
