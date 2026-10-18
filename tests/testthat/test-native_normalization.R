# Fixtures also exercise chemi_amos_method_with_spectra and
# ct_chemical_list_chemicals_search_start_with as native wrappers.
test_that("native vector wrappers normalize once before validation and iteration", {
  cases <- readRDS(test_path("fixtures/native-normalization.rds"))
  original <- .ct_legacy_query
  for (name in names(cases)) {
    case <- cases[[name]]
    count <- 0L
    calls <- list()
    local({
      withr::local_envvar(batch_limit = "2")
      local_mocked_bindings(
        .ct_legacy_query = function(query) {
          count <<- count + 1L
          original(query)
        },
        .ct_request = function(...) {
          calls[[length(calls) + 1L]] <<- list(...)
          if (name %in% c("chemi_amos_get_info_by_id", "chemi_alerts_groups_by_id"))
            list(list(input = unlist(list(...)$path_params, use.names = FALSE),
                      records = case$response)) else case$response
        },
        .package = "ComptoxR"
      )
      args <- case$inputs
      seed <- unlist(args[[case$key]], use.names = FALSE)[1L]
      args[[case$key]] <- if (is.character(seed)) c(seed, seed, "", NA_character_) else rep(seed, 2L)
      do.call(get(name, asNamespace("ComptoxR")), args)
      expect_identical(count, 1L, info = name)
      expect_length(calls, 1L)
      args[[case$key]] <- if (is.character(seed)) c("", NA_character_) else seed[FALSE]
      expect_error(do.call(get(name, asNamespace("ComptoxR")), args),
                   "Query must be a character vector")
      expect_identical(count, 2L, info = name)
      expect_length(calls, 1L)
    })
  }
})

test_that("multiple path parameters retain legacy object attribution", {
  withr::local_envvar(ctx_api_key = "local-normalization-key")
  cases <- readRDS(test_path("fixtures/native-primary-query.rds"))
  for (case in cases) {
    requests <- list()
    local({
      local_mocked_bindings(req_perform = function(req, ...) {
        requests[[length(requests) + 1L]] <<- req
        httr2::response(status_code = 200L,
          headers = list(`Content-Type` = "application/json"),
          body = charToRaw(case$json))
      }, .package = "httr2")
      actual <- do.call(get(case$name, asNamespace("ComptoxR")), case$inputs)
      expect_identical(actual, case$result, info = paste(case$name, case$json))
      expect_identical(vapply(requests, function(req) httr2::url_parse(req$url)$path, ""),
                       case$paths, info = case$name)
    })
  }
})

test_that("detail arrays normalize and split using the current batch setting", {
  withr::local_envvar(ctx_api_key = "local-normalization-key", batch_limit = "2")
  requests <- list()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"value":"ok"}]'))
  }, .package = "httr2")
  for (name in c("ct_chemical_detail_search_bulk", "ct_chemical_detail_search_by_dtxcid_bulk")) {
    requests <- list()
    fn <- get(name, asNamespace("ComptoxR"))
    result <- fn(list("one", "", NA_character_, "one", "café", "three"), "compact")
    expect_equal(nrow(result), 2L)
    expect_length(requests, 2L)
    expect_identical(requests[[1L]]$body$data, list("one", "café"))
    expect_identical(requests[[2L]]$body$data, list("three"))
    expect_identical(httr2::url_parse(requests[[1L]]$url)$query$projection, "compact")
    expect_error(fn(c("", NA_character_), projection = stop("option evaluated")),
                 "Query must be a character vector")
    expect_length(requests, 2L)
    withr::with_envvar(c(batch_limit = "1"), fn(c("one", "two")))
    expect_length(requests, 4L)
    withr::with_envvar(c(batch_limit = "0"), expect_error(fn("one"), "batch"))
    expect_length(requests, 4L)
  }
})

test_that("object attribution follows each fan-out input", {
  withr::local_envvar(ctx_api_key = "local-normalization-key")
  local_mocked_bindings(req_perform = function(req, ...) {
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"id":1}'))
  }, .package = "httr2")
  expect_identical(chemi_amos_record_ids_for_substance(c("one", "two"), "method"),
    list(structure(list(id = 1L), query = "one"), structure(list(id = 1L), query = "two")))
  expect_identical(ct_chemical_list_chemicals_search_equal(c("one", "two"), "chemical")$query,
                   c("one", "two"))
  for (fn in list(ct_chemical_detail_search_bulk, ct_chemical_detail_search_by_dtxcid_bulk)) {
    expect_identical(fn("one"), tibble::tibble(query = "one", id = 1L))
  }
})
