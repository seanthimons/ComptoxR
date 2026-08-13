load_multischema_pipeline <- function() {
  path <- testthat::test_path("..", "..", "dev", "stub_specs.R")
  testthat::skip_if_not(file.exists(path), "Maintainer-only test requires dev pipeline")
  suppressWarnings(suppressPackageStartupMessages(source(path, local = FALSE)))
}

test_that("Cheminformatics generation loads and collapses all schema stages", {
  load_multischema_pipeline()
  endpoints <- suppressWarnings(chemi_spec$build_endpoints())

  keyset <- endpoints[endpoints$fn == "chemi_amos_method_keyset_pagination", ]
  expect_identical(keyset$supported_schema_stages[[1]], c("staging", "development"))
  expect_identical(unname(keyset$schema_stage), "staging")
  expect_true(all(
    c(
      "chemi_amos_method_list",
      "chemi_amos_method_pagination",
      "chemi_amos_method_keyset_pagination",
      "chemi_amos_method_keyset_pagination_bulk"
    ) %in%
      endpoints$fn
  ))
  expect_identical(anyDuplicated(endpoints$fn), 0L)
})

test_that("identical stage contracts collapse and conflicts get deterministic suffixes", {
  load_multischema_pipeline()
  base <- tibble::tibble(
    source_file = c("chemi-demo-prod.json", "chemi-demo-staging.json", "chemi-demo-dev.json"),
    service_slug = "demo",
    route = "/api/demo/items/{id}",
    method = "GET",
    path_params = "id",
    query_params = "",
    body_params = "",
    path_param_metadata = list(list(), list(), list()),
    query_param_metadata = list(list(), list(), list()),
    body_param_metadata = list(list(), list(), list()),
    body_schema_type = "unknown",
    body_schema_full = list(list(), list(), list()),
    body_item_type = NA_character_,
    content_type = "application/json",
    request_type = "path",
    pagination_metadata = list(list(), list(), list())
  )

  identical_contracts <- collapse_chemi_stage_contracts(base)
  expect_equal(nrow(identical_contracts), 1L)
  expect_identical(
    identical_contracts$supported_schema_stages[[1]],
    c("public", "staging", "development")
  )

  base$query_params[2:3] <- "view"
  conflicts <- collapse_chemi_stage_contracts(base)
  expect_equal(nrow(conflicts), 2L)
  expect_identical(conflicts$variant_suffix, c("", "_staging"))
  expect_identical(conflicts$supported_schema_stages[[2]], c("staging", "development"))
})

test_that("generated stage configuration and AMOS call shapes are deterministic", {
  load_multischema_pipeline()
  endpoints <- suppressWarnings(chemi_spec$build_endpoints())
  first <- tempfile(fileext = ".yml")
  second <- tempfile(fileext = ".yml")
  write_generated_hook_config(endpoints, first)
  write_generated_hook_config(endpoints, second)
  expect_identical(readLines(first), readLines(second))

  wanted <- c(
    "chemi_amos_method_list",
    "chemi_amos_method_pagination",
    "chemi_amos_method_keyset_pagination",
    "chemi_amos_method_keyset_pagination_bulk"
  )
  rendered <- render_endpoint_stubs(endpoints[endpoints$fn %in% wanted, ], chemi_config)
  text <- stats::setNames(rendered$text, rendered$fn)

  expect_match(
    text[["chemi_amos_method_pagination"]],
    "function(limit, offset = 0, all_pages = TRUE, max_pages = 100)",
    fixed = TRUE
  )
  expect_match(text[["chemi_amos_method_pagination"]], "max_pages = max_pages", fixed = TRUE)
  expect_match(
    text[["chemi_amos_method_keyset_pagination"]],
    'pagination_cursor_location = "query"',
    fixed = TRUE
  )
  expect_match(
    text[["chemi_amos_method_keyset_pagination_bulk"]],
    'pagination_cursor_location = "body"',
    fixed = TRUE
  )
  expect_match(
    text[["chemi_amos_method_keyset_pagination_bulk"]],
    "path_params = c(limit = limit)",
    fixed = TRUE
  )
  expect_true(all(vapply(text, grepl, logical(1), pattern = "server = server", fixed = TRUE)))
  expect_false(grepl(
    "chemicals = chemicals",
    text[["chemi_amos_method_keyset_pagination_bulk"]],
    fixed = TRUE
  ))
})

test_that("object and array defaults render as valid R values", {
  load_multischema_pipeline()
  metadata <- list(
    filters = list(required = FALSE, type = "object", default = stats::setNames(list(), character())),
    sortModel = list(required = FALSE, type = "array", default = list())
  )

  parsed <- parse_function_params(
    "filters,sortModel",
    strategy = "options",
    metadata = metadata,
    has_path_params = TRUE
  )
  expect_silent(parse(text = paste0("function(", parsed$fn_signature, ") NULL")))
  expect_match(parsed$param_docs, "default: {}", fixed = TRUE)
  expect_match(parsed$param_docs, "default: []", fixed = TRUE)
})

test_that("a configured parameter order keeps unconfigured parameters in place", {
  load_multischema_pipeline()
  order <- stubgen_configured_parameter_order(
    list(extra_params = list(output = list(order = 5))),
    'smiles, endpoint, method = "consensus", format = "JSON", output = c("wide", "raw")'
  )

  expect_identical(order, c("smiles", "endpoint", "method", "format", "output"))
})

test_that("the rebuilt Cheminformatics tree has no obsolete experimental functions", {
  load_multischema_pipeline()
  remover <- testthat::test_path("..", "..", "dev", "remove_experimental.R")
  testthat::skip_if_not(
    file.exists(remover),
    "Maintainer-only test requires dev scripts"
  )
  remover_env <- new.env(parent = globalenv())
  source(remover, local = remover_env)

  endpoints <- suppressWarnings(chemi_spec$build_endpoints())
  report <- remover_env$scan_experimental_chemi_files(
    testthat::test_path("..", "..", "R")
  )
  selected <- report$file[report$status == "selected"]
  exported <- unlist(lapply(selected, function(path) {
    records <- remover_env$parse_exported_roxygen(path)
    vapply(records, `[[`, character(1), "name")
  }))

  expect_setequal(setdiff(exported, endpoints$fn), character())
})
