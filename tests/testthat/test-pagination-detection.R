# test-pagination-detection.R
# Unit tests for pagination pattern detection
# Tests all 7 PAGINATION_REGISTRY patterns, negative cases, and warning behavior

# Source dev/ dependencies (not part of package namespace)
source(here::here("dev/endpoint_eval/00_config.R"))
source(here::here("dev/endpoint_eval/04_openapi_parser.R"))

# ==============================================================================
# Test 1: Registry structure validation
# ==============================================================================

test_that("PAGINATION_REGISTRY has exactly 7 entries with expected names", {
  expect_equal(length(PAGINATION_REGISTRY), 7)
  expect_named(
    PAGINATION_REGISTRY,
    c(
      "offset_limit_path",
      "cursor_path",
      "page_number_query",
      "offset_size_body",
      "offset_size_query",
      "page_size_query",
      "page_items_query"
    ),
    ignore.order = FALSE
  )

  # Verify each entry has required fields
  for (entry_name in names(PAGINATION_REGISTRY)) {
    entry <- PAGINATION_REGISTRY[[entry_name]]
    expect_true("strategy" %in% names(entry), info = paste(entry_name, "has strategy"))
    expect_true("param_names" %in% names(entry), info = paste(entry_name, "has param_names"))
    expect_true("param_location" %in% names(entry), info = paste(entry_name, "has param_location"))
  }
})

# ==============================================================================
# Test 2: All 7 registry patterns are correctly detected
# ==============================================================================

test_that("offset_limit_path pattern is detected from route", {
  result <- detect_pagination(
    route = "/amos/method_pagination/{limit}/{offset}",
    path_params = "limit,offset",
    query_params = "",
    body_params = ""
  )

  expect_equal(result$strategy, "offset_limit")
  expect_equal(result$registry_key, "offset_limit_path")
  expect_equal(result$params, c("limit", "offset"))
  expect_equal(result$param_location, "path")
})

test_that("cursor_path pattern is detected from route + query", {
  result <- detect_pagination(
    route = "/amos/similar_structures_keyset_pagination/{limit}",
    path_params = "limit",
    query_params = "cursor",
    body_params = ""
  )

  expect_equal(result$strategy, "cursor")
  expect_equal(result$registry_key, "cursor_path")
  expect_equal(result$params, c("limit", "cursor"))
  expect_type(result$param_location, "character")
  expect_equal(length(result$param_location), 2)
})

test_that("page_number_query pattern is detected from query params", {
  result <- detect_pagination(
    route = "/hazard",
    path_params = "",
    query_params = "pageNumber",
    body_params = ""
  )

  expect_equal(result$strategy, "page_number")
  expect_equal(result$registry_key, "page_number_query")
  expect_equal(result$params, c("pageNumber"))
  expect_equal(result$param_location, "query")
})

test_that("offset_size_body pattern is detected from body params", {
  result <- detect_pagination(
    route = "/search",
    path_params = "",
    query_params = "",
    body_params = "offset,limit"
  )

  expect_equal(result$strategy, "offset_limit")
  expect_equal(result$registry_key, "offset_size_body")
  expect_equal(result$params, c("offset", "limit"))
  expect_equal(result$param_location, "body")
})

test_that("offset_size_query pattern is detected from query params", {
  result <- detect_pagination(
    route = "/search",
    path_params = "",
    query_params = "offset,size",
    body_params = ""
  )

  expect_equal(result$strategy, "offset_limit")
  expect_equal(result$registry_key, "offset_size_query")
  expect_equal(result$params, c("offset", "size"))
  expect_equal(result$param_location, "query")
})

test_that("page_size_query pattern is detected from query params", {
  result <- detect_pagination(
    route = "/resolver/classyfire",
    path_params = "",
    query_params = "page,size",
    body_params = ""
  )

  expect_equal(result$strategy, "page_size")
  expect_equal(result$registry_key, "page_size_query")
  expect_equal(result$params, c("page", "size"))
  expect_equal(result$param_location, "query")
})

test_that("page_items_query pattern is detected from query params", {
  result <- detect_pagination(
    route = "/resolver/pubchem",
    path_params = "",
    query_params = "page,itemsPerPage",
    body_params = ""
  )

  expect_equal(result$strategy, "page_size")
  expect_equal(result$registry_key, "page_items_query")
  expect_equal(result$params, c("page", "itemsPerPage"))
  expect_equal(result$param_location, "query")
})

# ==============================================================================
# Test 3: Negative tests - no false positives
# ==============================================================================

test_that("single-item GET returns strategy 'none'", {
  result <- detect_pagination(
    route = "/chemical/detail/{dtxsid}",
    path_params = "dtxsid",
    query_params = "",
    body_params = ""
  )

  expect_equal(result$strategy, "none")
  expect_equal(result$registry_key, NA_character_)
  expect_equal(length(result$params), 0)
  expect_equal(result$param_location, NA_character_)
  expect_match(result$description, "No pagination detected")
})

test_that("bulk POST without pagination returns strategy 'none'", {
  result <- detect_pagination(
    route = "/hazard",
    path_params = "",
    query_params = "projection",
    body_params = "",
    registry = PAGINATION_REGISTRY
  )

  expect_equal(result$strategy, "none")
  expect_equal(result$registry_key, NA_character_)
})

test_that("endpoint with no parameters returns strategy 'none'", {
  result <- detect_pagination(
    route = "/status",
    path_params = "",
    query_params = "",
    body_params = ""
  )

  expect_equal(result$strategy, "none")
  expect_equal(result$registry_key, NA_character_)
  expect_equal(length(result$params), 0)
})

# ==============================================================================
# Test 4: Dynamic schema validation
# ==============================================================================

test_that("detect_pagination matches patterns found in real schema files", {
  schema_dir <- here::here("schema")
  if (!dir.exists(schema_dir)) skip("Schema directory not available")

  # Find any schema with "pagination" in endpoint paths
  schema_files <- list.files(schema_dir, pattern = "\\.json$", full.names = TRUE)
  expect_true(length(schema_files) > 0, info = "Schema directory has JSON files")

  # Load one AMOS schema and verify pagination endpoint detected
  amos_files <- schema_files[grepl("amos", schema_files, ignore.case = TRUE)]
  if (length(amos_files) == 0) skip("No AMOS schema file found")

  amos <- jsonlite::read_json(amos_files[1])
  routes <- names(amos$paths)
  pag_routes <- routes[grepl("pagination", routes)]
  expect_true(length(pag_routes) > 0, info = "AMOS schema has pagination endpoints")

  # Verify at least one pagination route is detected
  detected_count <- 0
  for (route in pag_routes) {
    # Extract path param names from {param} patterns
    path_names <- regmatches(route, gregexpr("\\{([^}]+)\\}", route))[[1]]
    path_names <- gsub("[{}]", "", path_names)

    result <- detect_pagination(
      route = route,
      path_params = paste(path_names, collapse = ","),
      query_params = "",
      body_params = ""
    )

    # Count successful detections (not all may be detected - that's ok)
    if (result$strategy != "none") {
      detected_count <- detected_count + 1
    }
  }

  expect_true(detected_count > 0, info = paste("At least one pagination endpoint detected from", length(pag_routes), "candidates"))
})

# ==============================================================================
# Test 5: Warning for unmatched pagination-like params
# ==============================================================================

test_that("detect_pagination warns for unmatched pagination-like parameters", {
  expect_warning(
    result <- detect_pagination(
      route = "/custom",
      path_params = "",
      query_params = "skip,top",
      body_params = ""
    ),
    regexp = "Parameters resemble pagination but no registry pattern matched"
  )

  # Should still return strategy "none"
  expect_equal(result$strategy, "none")
  expect_equal(result$registry_key, NA_character_)
})

test_that("detect_pagination warns with correct suspicious params", {
  expect_warning(
    detect_pagination(
      route = "/test",
      path_params = "",
      query_params = "before,after,count",
      body_params = ""
    ),
    regexp = "Suspicious params.*before.*after.*count"
  )
})

test_that("detect_pagination does not warn for normal non-paginated endpoints", {
  expect_no_warning(
    result <- detect_pagination(
      route = "/chemical/detail/{dtxsid}",
      path_params = "dtxsid",
      query_params = "projection",
      body_params = ""
    )
  )

  expect_equal(result$strategy, "none")
})

test_that("warning includes route and PAGINATION_REGISTRY suggestion", {
  expect_warning(
    detect_pagination(
      route = "/api/test",
      path_params = "",
      query_params = "startIndex",
      body_params = ""
    ),
    regexp = "Route.*api/test.*Consider adding.*PAGINATION_REGISTRY"
  )
})
