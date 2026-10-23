test_that("held fan-out and array wrappers retain legacy input cleanup", {
  withr::local_envvar(c(ctx_api_key = "local-test-key", batch_limit = "2"))
  requests <- list()
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"id":"one"}]'))
  }, .package = "httr2")

  values <- c("one", "one", "", NA_character_)
  chemi_amos_get_info_by_id(values)
  ct_bioactivity_assay_search_by_gene(values)
  ct_chemical_extra_data_search_bulk(values)
  expect_length(requests, 3L)
  expect_true(endsWith(requests[[1]]$url, "/one"))
  expect_true(endsWith(requests[[2]]$url, "/one"))
  expect_identical(as.character(jsonlite::toJSON(requests[[3]]$body$data, auto_unbox = TRUE)), '["one"]')

  ct_chemical_extra_data_search_bulk(c("one", "two", "three", "one", "", NA_character_))
  expect_length(requests, 5L)
  expect_identical(lengths(lapply(requests[4:5], function(req) req$body$data)), c(2L, 1L))
  expect_error(chemi_amos_get_info_by_id(c("", NA_character_)), "Query must be a character vector")
  expect_error(ct_chemical_extra_data_search_bulk(character()), "Query must be a character vector")
  expect_length(requests, 5L)
})
