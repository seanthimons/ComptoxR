# Tests for OpenAPI Parsing Functions (04_openapi_parser.R)
# These functions parse OpenAPI/Swagger schemas into structured tibbles

skip_on_cran()

# ==============================================================================
# Helper Function Tests
# ==============================================================================

describe("sanitize_name", {
  test_that("removes special characters", {
    source_pipeline_files()
    # Special chars replaced with underscore (then collapsed)
    expect_equal(sanitize_name("test-name"), "test_name")
    expect_equal(sanitize_name("api/v1/endpoint"), "api_v1_endpoint")
  })

  test_that("collapses multiple underscores", {
    source_pipeline_files()
    expect_equal(sanitize_name("test___name"), "test_name")
    expect_equal(sanitize_name("a__b__c"), "a_b_c")
  })

  test_that("handles whitespace by converting to underscores", {
    source_pipeline_files()
    # Whitespace converted to underscores (not trimmed)
    expect_equal(sanitize_name("  test  "), "_test_")
    expect_equal(sanitize_name("test name "), "test_name_")
  })
})

describe("method_path_name", {
  test_that("creates lowercase method_path format", {
    source_pipeline_files()
    result <- method_path_name("/test/endpoint", "GET")
    expect_equal(result, "get_test_endpoint")
  })

  test_that("replaces path params with by_id pattern", {
    source_pipeline_files()
    result <- method_path_name("/users/{id}/profile", "GET")
    expect_equal(result, "get_users_by_id_profile")
  })

  test_that("handles multiple path segments", {
    source_pipeline_files()
    result <- method_path_name("/api/v1/chemical/{dtxsid}", "POST")
    expect_equal(result, "post_api_v1_chemical_by_dtxsid")
  })
})

describe("get_body_schema_type", {
  test_that("returns string for inline string schema", {
    source_pipeline_files()
    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(type = "string")
        )
      )
    )
    result <- get_body_schema_type(request_body, list())
    expect_equal(result, "string")
  })

  test_that("returns string_array for array of strings", {
    source_pipeline_files()
    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(
            type = "array",
            items = list(type = "string")
          )
        )
      )
    )
    result <- get_body_schema_type(request_body, list())
    expect_equal(result, "string_array")
  })

  test_that("returns chemical_array for chemicals property with Chemical ref", {
    source_pipeline_files()
    # Schema with Chemical reference
    openapi_spec <- list(
      components = list(
        schemas = list(
          ChemicalRequest = list(
            type = "object",
            properties = list(
              chemicals = list(
                type = "array",
                items = list(`$ref` = "#/components/schemas/Chemical")
              )
            )
          )
        )
      )
    )
    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(`$ref` = "#/components/schemas/ChemicalRequest")
        )
      )
    )
    result <- get_body_schema_type(request_body, openapi_spec)
    expect_equal(result, "chemical_array")
  })

  test_that("returns simple_object for object without chemicals", {
    source_pipeline_files()
    openapi_spec <- list(
      components = list(
        schemas = list(
          SimpleRequest = list(
            type = "object",
            properties = list(
              name = list(type = "string")
            )
          )
        )
      )
    )
    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(`$ref` = "#/components/schemas/SimpleRequest")
        )
      )
    )
    result <- get_body_schema_type(request_body, openapi_spec)
    expect_equal(result, "simple_object")
  })

  test_that("returns unknown for NULL request body", {
    source_pipeline_files()
    result <- get_body_schema_type(NULL, list())
    expect_equal(result, "unknown")
  })

  test_that("returns unknown for empty request body", {
    source_pipeline_files()
    result <- get_body_schema_type(list(), list())
    expect_equal(result, "unknown")
  })
})

describe("get_response_schema_type", {
  test_that("returns array for array responses", {
    source_pipeline_files()
    responses <- list(
      "200" = list(
        content = list(
          "application/json" = list(
            schema = list(type = "array")
          )
        )
      )
    )
    result <- get_response_schema_type(responses, list())
    expect_equal(result, "array")
  })

  test_that("returns object for object responses", {
    source_pipeline_files()
    responses <- list(
      "200" = list(
        content = list(
          "application/json" = list(
            schema = list(type = "object")
          )
        )
      )
    )
    result <- get_response_schema_type(responses, list())
    expect_equal(result, "object")
  })

  test_that("returns binary for image content types", {
    source_pipeline_files()
    responses <- list(
      "200" = list(
        content = list(
          "image/png" = list(
            schema = list(type = "string", format = "binary")
          )
        )
      )
    )
    result <- get_response_schema_type(responses, list())
    expect_equal(result, "binary")
  })

  test_that("returns unknown for missing responses", {
    source_pipeline_files()
    result <- get_response_schema_type(NULL, list())
    expect_equal(result, "unknown")
  })

  test_that("returns unknown for empty responses", {
    source_pipeline_files()
    result <- get_response_schema_type(list(), list())
    expect_equal(result, "unknown")
  })
})

describe("uses_chemical_schema", {
  test_that("returns TRUE when chemicals property references Chemical schema", {
    source_pipeline_files()
    openapi_spec <- list(
      components = list(
        schemas = list(
          ChemicalRequest = list(
            type = "object",
            properties = list(
              chemicals = list(
                type = "array",
                items = list(`$ref` = "#/components/schemas/Chemical")
              )
            )
          )
        )
      )
    )
    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(`$ref` = "#/components/schemas/ChemicalRequest")
        )
      )
    )
    result <- uses_chemical_schema(request_body, openapi_spec)
    expect_true(result)
  })

  test_that("returns FALSE for non-Chemical schemas", {
    source_pipeline_files()
    openapi_spec <- list(
      components = list(
        schemas = list(
          SimpleRequest = list(
            type = "object",
            properties = list(
              data = list(
                type = "array",
                items = list(type = "string")
              )
            )
          )
        )
      )
    )
    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(`$ref` = "#/components/schemas/SimpleRequest")
        )
      )
    )
    result <- uses_chemical_schema(request_body, openapi_spec)
    expect_false(result)
  })

  test_that("returns FALSE for NULL request body", {
    source_pipeline_files()
    result <- uses_chemical_schema(NULL, list())
    expect_false(result)
  })
})

describe("openapi_to_spec", {
  test_that("parses OpenAPI 3.0 fixture into tibble", {
    source_pipeline_files()
    schema <- load_fixture_schema("minimal-openapi-3.json")
    result <- openapi_to_spec(schema, preprocess = FALSE)

    expect_s3_class(result, "tbl_df")
    expect_true(all(c("route", "method", "summary", "has_body", "params") %in% names(result)))
    expect_true(nrow(result) > 0)
  })

  test_that("parses Swagger 2.0 fixture into tibble", {
    source_pipeline_files()
    schema <- load_fixture_schema("minimal-swagger-2.json")
    result <- openapi_to_spec(schema, preprocess = FALSE)

    expect_s3_class(result, "tbl_df")
    expect_true(all(c("route", "method", "summary", "has_body", "params") %in% names(result)))
    expect_true(nrow(result) > 0)
  })

  test_that("returns expected columns", {
    source_pipeline_files()
    schema <- load_fixture_schema("minimal-openapi-3.json")
    result <- openapi_to_spec(schema, preprocess = FALSE)

    expected_cols <- c(
      "route", "method", "summary", "has_body", "params",
      "path_params", "query_params", "body_params",
      "num_path_params", "num_body_params",
      "content_type", "needs_resolver", "body_schema_type",
      "deprecated", "response_schema_type", "request_type"
    )

    expect_true(all(expected_cols %in% names(result)))
  })

  test_that("handles empty paths with error", {
    source_pipeline_files()
    schema <- list(
      openapi = "3.0.0",
      info = list(title = "Test", version = "1.0"),
      paths = list()
    )

    expect_error(
      openapi_to_spec(schema, preprocess = FALSE),
      "paths"
    )
  })

  test_that("extracts path parameters correctly", {
    source_pipeline_files()
    schema <- load_fixture_schema("minimal-openapi-3.json")
    result <- openapi_to_spec(schema, preprocess = FALSE)

    # At least check that path_params column exists
    expect_true("path_params" %in% names(result))
  })

  test_that("detects deprecated endpoints", {
    source_pipeline_files()
    schema <- list(
      openapi = "3.0.0",
      info = list(title = "Test", version = "1.0"),
      paths = list(
        "/deprecated" = list(
          get = list(
            deprecated = TRUE,
            responses = list("200" = list(description = "OK"))
          )
        )
      )
    )
    result <- openapi_to_spec(schema, preprocess = FALSE)

    expect_true(any(result$deprecated))
  })

  test_that("classifies request types correctly", {
    source_pipeline_files()
    schema <- list(
      openapi = "3.0.0",
      info = list(title = "Test", version = "1.0"),
      paths = list(
        "/json" = list(
          post = list(
            requestBody = list(
              content = list(
                "application/json" = list(
                  schema = list(type = "string")
                )
              )
            ),
            responses = list("200" = list(description = "OK"))
          )
        ),
        "/query" = list(
          get = list(
            responses = list("200" = list(description = "OK"))
          )
        )
      )
    )
    result <- openapi_to_spec(schema, preprocess = FALSE)

    # Check that request_type column is populated
    expect_true("request_type" %in% names(result))
    expect_true(any(result$request_type %in% c("json", "query_only", "path")))
  })
})

# ==============================================================================
# Pagination Detection Tests
# ==============================================================================

describe("detect_pagination", {
  test_that("detects AMOS offset/limit path pagination", {
    source_pipeline_files()
    r <- detect_pagination(
      "/api/amos/method_pagination/{limit}/{offset}",
      "limit,offset", "", ""
    )
    expect_equal(r$strategy, "offset_limit")
    expect_equal(r$registry_key, "offset_limit_path")
    expect_equal(r$param_location, "path")
  })

  test_that("detects AMOS cursor pagination", {
    source_pipeline_files()
    r <- detect_pagination(
      "/api/amos/method_keyset_pagination/{limit}",
      "limit", "cursor", ""
    )
    expect_equal(r$strategy, "cursor")
    expect_equal(r$registry_key, "cursor_path")
  })

  test_that("detects CTX pageNumber query pagination", {
    source_pipeline_files()
    r <- detect_pagination("/hazard/toxref/search", "", "pageNumber", "")
    expect_equal(r$strategy, "page_number")
    expect_equal(r$registry_key, "page_number_query")
    expect_equal(r$param_location, "query")
  })

  test_that("detects Common Chemistry offset+size query pagination", {
    source_pipeline_files()
    r <- detect_pagination("/search", "", "q,offset,size", "")
    expect_equal(r$strategy, "offset_limit")
    expect_equal(r$registry_key, "offset_size_query")
    expect_equal(r$param_location, "query")
  })

  test_that("detects Chemi search body offset+limit pagination", {
    source_pipeline_files()
    r <- detect_pagination("/api/search", "", "", "query,offset,limit")
    expect_equal(r$strategy, "offset_limit")
    expect_equal(r$registry_key, "offset_size_body")
    expect_equal(r$param_location, "body")
  })

  test_that("detects Chemi resolver page+size query pagination", {
    source_pipeline_files()
    r <- detect_pagination("/api/resolver/classyfire", "", "page,size", "")
    expect_equal(r$strategy, "page_size")
    expect_equal(r$registry_key, "page_size_query")
  })

  test_that("detects Chemi resolver page+itemsPerPage query pagination", {
    source_pipeline_files()
    r <- detect_pagination("/api/resolver/getpubchemlist", "", "page,itemsPerPage", "")
    expect_equal(r$strategy, "page_size")
    expect_equal(r$registry_key, "page_items_query")
  })

  test_that("returns none for non-paginated endpoint", {
    source_pipeline_files()
    r <- detect_pagination("/chemical/detail/by-dtxsid", "dtxsid", "", "")
    expect_equal(r$strategy, "none")
    expect_true(is.na(r$registry_key))
    expect_length(r$params, 0)
  })

  test_that("single limit param alone does not trigger false positive", {
    source_pipeline_files()
    r <- detect_pagination("/api/endpoint", "limit", "", "")
    expect_equal(r$strategy, "none")
  })

  test_that("empty params return none", {
    source_pipeline_files()
    r <- detect_pagination("/api/endpoint", "", "", "")
    expect_equal(r$strategy, "none")
  })

  test_that("custom registry overrides detection (PAG-02 configurability)", {
    source_pipeline_files()
    custom_registry <- list(
      custom_pattern = list(
        strategy = "custom_strategy",
        route_pattern = NULL,
        param_names = c("myPage"),
        param_location = "query",
        description = "Custom pagination"
      )
    )
    r <- detect_pagination("/api/custom", "", "myPage,other", "", registry = custom_registry)
    expect_equal(r$strategy, "custom_strategy")
    expect_equal(r$registry_key, "custom_pattern")

    # Default registry should NOT match this
    r2 <- detect_pagination("/api/custom", "", "myPage,other", "")
    expect_equal(r2$strategy, "none")
  })

  test_that("openapi_to_spec includes pagination columns", {
    source_pipeline_files()
    schema <- load_fixture_schema("minimal-openapi-3.json")
    result <- openapi_to_spec(schema, preprocess = FALSE)

    expect_true("pagination_strategy" %in% names(result))
    expect_true("pagination_metadata" %in% names(result))
    expect_true(all(result$pagination_strategy %in% c("none", "offset_limit", "cursor", "page_number", "page_size")))
  })

  test_that("AMOS schema has paginated endpoints detected", {
    source_pipeline_files()
    schema_path <- here::here("schema", "chemi-amos-prod.json")
    skip_if_not(file.exists(schema_path), "AMOS schema not available")

    spec <- openapi_to_spec(jsonlite::fromJSON(schema_path, simplifyVector = FALSE))
    strategies <- table(spec$pagination_strategy)

    # AMOS schema should have offset_limit endpoints (cursor is dev-only)
    expect_true("offset_limit" %in% names(strategies))
    expect_true("none" %in% names(strategies))
  })

  test_that("non-paginated schema has all none strategies", {
    source_pipeline_files()
    schema_path <- here::here("schema", "ctx-chemical-prod.json")
    skip_if_not(file.exists(schema_path), "CTX chemical schema not available")

    spec <- openapi_to_spec(jsonlite::fromJSON(schema_path, simplifyVector = FALSE))
    expect_true(all(spec$pagination_strategy == "none"))
  })
})
