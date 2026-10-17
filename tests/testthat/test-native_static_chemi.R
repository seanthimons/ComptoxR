test_that("native Chemi group and standardization GETs preserve request contracts", {
  requests <- list()
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"id":"one","flag":false,"value":0}]'))
  }, .package = "httr2")
  for (result in list(chemi_alerts_groups(), chemi_stdizer_groups(),
    chemi_stdizer("workflow /é", "C/C=N\\O"))) {
    expect_identical(result[[1]]$id, "one")
    expect_identical(result[[1]]$flag, FALSE)
    expect_identical(result[[1]]$value, 0L)
  }
  expect_true(endsWith(requests[[1]]$url, "/api/alerts/groups"))
  expect_true(endsWith(requests[[2]]$url, "/api/stdizer/groups"))
  query <- httr2::url_parse(requests[[3]]$url)$query
  expect_identical(query, list(workflow = "workflow /é", smiles = "C/C=N\\O"))
  for (request in requests) {
    expect_identical(request$method, "GET")
    expect_null(request$body)
    expect_identical(request$headers$Accept, "application/json")
    expect_false("x-api-key" %in% names(request$headers))
  }
  expect_error(chemi_stdizer("workflow"), "smiles")
  expect_error(chemi_stdizer("workflow", 0), "Invalid")
  expect_length(requests, 3L)
})
