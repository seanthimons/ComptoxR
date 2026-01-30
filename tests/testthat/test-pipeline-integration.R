# Pipeline Integration Tests - End-to-end verification
# Tests complete pipeline: schema -> stub -> execution
#
# Note: EPI Suite integration tests excluded - no epi-*-prod.json schemas
# exist in schema/ directory. Can be added when schemas become available.

skip_on_cran()

# ==============================================================================
# E2E: CompTox Dashboard Pipeline (OpenAPI 3.0)
# ==============================================================================

describe("E2E: CompTox Dashboard Pipeline", {
  test_that("generates valid stubs from ctx-hazard-prod schema", {
    skip_on_cran()

    # Skip if no cassette AND no API key (first-run scenario)
    cassette_path <- here::here("tests/testthat/fixtures/_vcr/integration-ctx-hazard.yml")
    has_cassette <- file.exists(cassette_path)
    has_api_key <- nzchar(Sys.getenv("ctx_api_key"))
    skip_if(!has_cassette && !has_api_key,
            message = "First run requires ctx_api_key to record cassette")

    vcr::use_cassette("integration-ctx-hazard", {
      # 1. Load real production schema
      schema_path <- here::here("schema/ctx-hazard-prod.json")
      expect_true(file.exists(schema_path),
                  info = "ctx-hazard-prod.json schema must exist")
      schema <- jsonlite::fromJSON(schema_path, simplifyVector = FALSE)
      expect_type(schema, "list")
      expect_true(length(schema) > 0)

      # 2. Source pipeline
      source_pipeline_files()

      # 3. Parse schema to spec
      spec <- openapi_to_spec(schema)
      expect_s3_class(spec, "data.frame")
      expect_true(nrow(spec) > 0, info = "Schema should parse to at least one endpoint")

      # 4. Select a POST endpoint with meaningful parameters
      # Prefer endpoints with body parameters for comprehensive testing
      post_endpoints <- spec[spec$method == "POST", ]
      expect_true(nrow(post_endpoints) > 0,
                  info = "ctx-hazard schema should have POST endpoints")

      # Pick first POST endpoint
      first_endpoint <- post_endpoints[1, ]

      # 5. Generate stub for the endpoint
      # Extract parameters from spec row
      fn_name <- paste0("ct_", sanitize_name(first_endpoint$endpoint))

      stub <- build_function_stub(
        fn = fn_name,
        endpoint = first_endpoint$endpoint,
        method = first_endpoint$method,
        title = first_endpoint$title %||% paste("Generated function for", first_endpoint$endpoint),
        batch_limit = first_endpoint$batch_limit,
        path_param_info = list(
          primary = first_endpoint$path_params_primary %||% "",
          additional = if (!is.na(first_endpoint$path_params_additional) &&
                          nzchar(first_endpoint$path_params_additional)) {
            strsplit(first_endpoint$path_params_additional, ",")[[1]]
          } else {
            character(0)
          }
        ),
        query_param_info = list(
          params = if (!is.na(first_endpoint$query_params) &&
                      nzchar(first_endpoint$query_params)) {
            strsplit(first_endpoint$query_params, ",")[[1]]
          } else {
            character(0)
          },
          metadata = first_endpoint$query_params_metadata %||% list()
        ),
        body_param_info = list(
          params = if (!is.na(first_endpoint$body_params) &&
                      nzchar(first_endpoint$body_params)) {
            strsplit(first_endpoint$body_params, ",")[[1]]
          } else {
            character(0)
          },
          metadata = first_endpoint$body_params_metadata %||% list()
        ),
        content_type = first_endpoint$response_content_type %||% "application/json",
        config = get_stubgen_config(),
        needs_resolver = first_endpoint$needs_resolver %||% FALSE,
        body_schema_type = first_endpoint$body_schema_type %||% "unknown",
        deprecated = first_endpoint$deprecated %||% FALSE,
        response_schema_type = first_endpoint$response_schema_type %||% "unknown",
        request_type = first_endpoint$request_type %||% "json"
      )

      # 6. Verify stub is valid R code
      expect_type(stub, "character")
      expect_true(nzchar(stub), info = "Generated stub should not be empty")

      parsed <- tryCatch(
        parse(text = stub),
        error = function(e) {
          cli::cli_alert_danger("Failed to parse generated stub:")
          cli::cli_text(stub)
          cli::cli_alert_danger("Parse error: {conditionMessage(e)}")
          NULL
        }
      )
      expect_false(is.null(parsed), info = "Generated stub must be valid R syntax")

      # 7. Execute stub to define the function
      eval(parsed, envir = .GlobalEnv)

      # 8. Verify function exists and is callable
      expect_true(exists(fn_name, envir = .GlobalEnv),
                  info = paste("Function", fn_name, "should be defined"))

      generated_fn <- get(fn_name, envir = .GlobalEnv)
      expect_type(generated_fn, "closure")

      # 9. Call generated function with test DTXSID and verify result
      # Use Aspirin - a well-known chemical in the CompTox Dashboard
      test_dtxsid <- "DTXSID7020182"

      result <- tryCatch(
        generated_fn(test_dtxsid),
        error = function(e) {
          cli::cli_alert_warning("Function call failed: {conditionMessage(e)}")
          NULL
        }
      )

      # Verify result is valid (tibble or list with data)
      expect_false(is.null(result),
                   info = "Generated function should return data, not NULL")
      expect_true(
        is.data.frame(result) || is.list(result),
        info = "Generated function must return data frame or list"
      )

      if (is.data.frame(result)) {
        expect_true(nrow(result) >= 0, info = "Result should be a valid tibble")
      } else if (is.list(result)) {
        expect_true(length(result) >= 0, info = "Result should be a valid list")
      }

      # Cleanup: Remove generated function from global environment
      if (exists(fn_name, envir = .GlobalEnv)) {
        rm(list = fn_name, envir = .GlobalEnv)
      }
    })
  })
})

# ==============================================================================
# E2E: Cheminformatics Pipeline (Swagger 2.0)
# ==============================================================================

describe("E2E: Cheminformatics Pipeline", {
  test_that("generates valid stubs from chemi-safety-prod schema", {
    skip_on_cran()

    # Skip if no cassette AND no API key (first-run scenario)
    cassette_path <- here::here("tests/testthat/fixtures/_vcr/integration-chemi-safety.yml")
    has_cassette <- file.exists(cassette_path)
    has_api_key <- nzchar(Sys.getenv("ctx_api_key"))
    skip_if(!has_cassette && !has_api_key,
            message = "First run requires ctx_api_key to record cassette")

    vcr::use_cassette("integration-chemi-safety", {
      # 1. Load real production schema (Swagger 2.0)
      schema_path <- here::here("schema/chemi-safety-prod.json")
      expect_true(file.exists(schema_path),
                  info = "chemi-safety-prod.json schema must exist")
      schema <- jsonlite::fromJSON(schema_path, simplifyVector = FALSE)
      expect_type(schema, "list")
      expect_true(length(schema) > 0)

      # Verify it's Swagger 2.0
      expect_true(!is.null(schema$swagger),
                  info = "Schema should have 'swagger' field for Swagger 2.0")

      # 2. Source pipeline
      source_pipeline_files()

      # 3. Parse schema to spec
      spec <- openapi_to_spec(schema)
      expect_s3_class(spec, "data.frame")
      expect_true(nrow(spec) > 0, info = "Schema should parse to at least one endpoint")

      # 4. Select a POST endpoint with meaningful parameters
      post_endpoints <- spec[spec$method == "POST", ]
      expect_true(nrow(post_endpoints) > 0,
                  info = "chemi-safety schema should have POST endpoints")

      # Pick first POST endpoint
      first_endpoint <- post_endpoints[1, ]

      # 5. Generate stub for the endpoint
      fn_name <- paste0("chemi_", sanitize_name(first_endpoint$endpoint))

      stub <- build_function_stub(
        fn = fn_name,
        endpoint = first_endpoint$endpoint,
        method = first_endpoint$method,
        title = first_endpoint$title %||% paste("Generated function for", first_endpoint$endpoint),
        batch_limit = first_endpoint$batch_limit,
        path_param_info = list(
          primary = first_endpoint$path_params_primary %||% "",
          additional = if (!is.na(first_endpoint$path_params_additional) &&
                          nzchar(first_endpoint$path_params_additional)) {
            strsplit(first_endpoint$path_params_additional, ",")[[1]]
          } else {
            character(0)
          }
        ),
        query_param_info = list(
          params = if (!is.na(first_endpoint$query_params) &&
                      nzchar(first_endpoint$query_params)) {
            strsplit(first_endpoint$query_params, ",")[[1]]
          } else {
            character(0)
          },
          metadata = first_endpoint$query_params_metadata %||% list()
        ),
        body_param_info = list(
          params = if (!is.na(first_endpoint$body_params) &&
                      nzchar(first_endpoint$body_params)) {
            strsplit(first_endpoint$body_params, ",")[[1]]
          } else {
            character(0)
          },
          metadata = first_endpoint$body_params_metadata %||% list()
        ),
        content_type = first_endpoint$response_content_type %||% "application/json",
        config = get_stubgen_config(),
        needs_resolver = first_endpoint$needs_resolver %||% FALSE,
        body_schema_type = first_endpoint$body_schema_type %||% "unknown",
        deprecated = first_endpoint$deprecated %||% FALSE,
        response_schema_type = first_endpoint$response_schema_type %||% "unknown",
        request_type = first_endpoint$request_type %||% "json"
      )

      # 6. Verify stub is valid R code
      expect_type(stub, "character")
      expect_true(nzchar(stub), info = "Generated stub should not be empty")

      parsed <- tryCatch(
        parse(text = stub),
        error = function(e) {
          cli::cli_alert_danger("Failed to parse generated stub:")
          cli::cli_text(stub)
          cli::cli_alert_danger("Parse error: {conditionMessage(e)}")
          NULL
        }
      )
      expect_false(is.null(parsed), info = "Generated stub must be valid R syntax")

      # 7. Execute stub to define the function
      eval(parsed, envir = .GlobalEnv)

      # 8. Verify function exists and is callable
      expect_true(exists(fn_name, envir = .GlobalEnv),
                  info = paste("Function", fn_name, "should be defined"))

      generated_fn <- get(fn_name, envir = .GlobalEnv)
      expect_type(generated_fn, "closure")

      # 9. Call generated function with test DTXSID and verify result
      # Use Aspirin - a well-known chemical
      test_dtxsid <- "DTXSID7020182"

      result <- tryCatch(
        generated_fn(test_dtxsid),
        error = function(e) {
          cli::cli_alert_warning("Function call failed: {conditionMessage(e)}")
          NULL
        }
      )

      # Verify result is valid (tibble or list with data)
      expect_false(is.null(result),
                   info = "Generated function should return data, not NULL")
      expect_true(
        is.data.frame(result) || is.list(result),
        info = "Generated function must return data frame or list"
      )

      if (is.data.frame(result)) {
        expect_true(nrow(result) >= 0, info = "Result should be a valid tibble")
      } else if (is.list(result)) {
        expect_true(length(result) >= 0, info = "Result should be a valid list")
      }

      # Cleanup: Remove generated function from global environment
      if (exists(fn_name, envir = .GlobalEnv)) {
        rm(list = fn_name, envir = .GlobalEnv)
      }
    })
  })
})
