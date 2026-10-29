test_that("native CTX list and range GETs preserve all path parameters", {
  withr::local_envvar(ctx_api_key = "local-ctx-key")
  requests <- list()
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200, headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"id":1}]'))
  }, .package = "httr2")
  result <- ct_chemical_list_chemicals_search_contain(c("list one", "list/two"), "bisphenol")
  expect_equal(nrow(result), 2L)
  expect_true(endsWith(requests[[1]]$url, "/contain/list%20one/bisphenol"))
  expect_true(endsWith(requests[[2]]$url, "/contain/list%2Ftwo/bisphenol"))
  expect_true("x-api-key" %in% names(requests[[1]]$headers))
  ct_chemical_property_experimental_search_by_range("Melting Point", 0, 100)
  expect_true(endsWith(requests[[3]]$url, "/by-range/Melting%20Point/0/100"))
  expect_error(ct_chemical_property_experimental_search_by_range("Melting Point", 0), "end")
  expect_error(ct_chemical_property_predicted_search_by_range("1", "0", 100), "Invalid")
  expect_length(requests, 3L)
})

test_that("native AMOS PDF requests retain binary response bytes", {
  requests <- list()
  bytes <- charToRaw("%PDF-test\n")
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200, headers = list(`Content-Type` = "application/pdf"), body = bytes)
  }, .package = "httr2")
  expect_identical(chemi_amos_get_pdf("method", "id/one"), list(bytes))
  expect_true(endsWith(requests[[1]]$url, "/api/amos/get_pdf/method/id%2Fone"))
  expect_error(chemi_amos_get_pdf("method"), "internal_id")
  expect_length(requests, 1L)
})
