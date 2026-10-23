test_that("reviewed AMOS routes use declared required parameters and encoded paths", {
  requests <- list()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"id":"one"}]'))
  }, .package = "httr2")

  expect_identical(chemi_amos_get_similar_structures("type / test", "ID + one"),
    list(list(id = "one")))
  expect_identical(chemi_amos_list_sources_by_record_type("fact sheet"),
    list(list(id = "one")))
  expect_true(endsWith(requests[[1L]]$url,
    "/api/amos/get_similar_structures/type%20%2F%20test/ID%20%2B%20one"))
  expect_true(endsWith(requests[[2L]]$url,
    "/api/amos/list_sources_by_record_type/fact%20sheet"))
  expect_true(all(vapply(requests, function(req) is.null(req$body), logical(1))))
  expect_identical(names(formals(chemi_amos_get_similar_structures)),
    c("identifier_type", "identifier"))
  expect_identical(names(formals(chemi_amos_list_sources_by_record_type)), "record_type")

  expect_identical(chemi_amos_list_sources_by_record_type(c("method", "method", NA, "")),
    list(list(id = "one")))
  expect_length(requests, 3L)
  expect_error(chemi_amos_get_similar_structures(NULL, "one"))
  expect_error(chemi_amos_get_similar_structures("type", NULL))
  expect_length(requests, 3L)
})
