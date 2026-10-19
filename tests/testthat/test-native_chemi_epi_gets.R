test_that("native Chemi GETs preserve encoded inputs and schema defaults", {
  requests <- list()
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"id":1}]'))
  }, .package = "httr2")

  result <- chemi_resolver_lookup("café +/&")
  expect_identical(result, tibble::tibble(id = 1L))
  query <- httr2::url_parse(requests[[1]]$url)$query
  expect_identical(query, list(query = "café +/&", idType = "AnyId", fuzzy = "Not", mol = "false"))

  result <- chemi_stdizer_groups_by_id(c("group one", "group/two"))
  expect_length(result, 2L)
  expect_true(endsWith(requests[[2]]$url, "/api/stdizer/groups/group%20one"))
  expect_true(endsWith(requests[[3]]$url, "/api/stdizer/groups/group%2Ftwo"))
})

test_that("native EPI GETs validate choices and omit absent optional fields", {
  requests <- list()
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200,
      headers = list(`Content-Type` = "application/json"), body = charToRaw('[]'))
  }, .package = "httr2")
  epi_ecosar_polymer_amphoteric("INSOLUBLE")
  query <- httr2::url_parse(requests[[1]]$url)$query
  expect_identical(query, list(solubilityType = "INSOLUBLE", polymerType = "carbon"))
  expect_error(epi_ecosar_polymer_amphoteric("invalid"), "Invalid")
  expect_length(requests, 1L)
})
