# Tests for ct_related (hand-written: mocks the native .ct_request; legacy dashboard routes have no production schema).

test_that("ct_related passes request metadata to helper", {
  if (!exists("generated_contract_response", mode = "function")) {
    source(file.path("tests", "testthat", "helper-generated-contracts.R"))
  }
  generated_contract_ensure_package()

  calls <- list()
  mock_helper <- function(...) {
    captured <- list(...)
    captured$.helper <- ".ct_request"
    calls[[length(calls) + 1L]] <<- captured
    list()
  }

  testthat::local_mocked_bindings(
    .ct_request = mock_helper,
    .package = "ComptoxR"
  )

  result <- try(suppressWarnings(suppressMessages(ComptoxR::ct_related(query = "DTXSID7020182"))), silent = TRUE)
  expect_gt(length(calls), 0L)
  call <- calls[[1L]]
  expect_true(is.list(call))
  expect_equal(call$.helper, ".ct_request")
  expect_equal(call[["method"]], "GET")
  expect_equal(call[["path"]], "/related-substances/search/by-dtxsid")
  expect_equal(call[["query"]], list(id = "DTXSID7020182"))
  expect_equal(call[["server"]], list(url = "https://comptox.epa.gov/dashboard-api/ccdapp2"))
  expect_null(call[["auth"]])
  expect_null(call[["response_policy"]])
})

test_that("ct_related warns and skips an item whose request fails", {
  testthat::local_mocked_bindings(
    .ct_request = function(...) {
      if (identical(list(...)$query$id, "DTXSID_BAD")) stop("HTTP 404")
      list(data = list(
        list(dtxsid = "DTXSID1", relationship = "Searched Chemical"),
        list(dtxsid = "DTXSID2", relationship = "related")
      ))
    },
    .package = "ComptoxR"
  )
  expect_warning(
    result <- suppressMessages(ct_related(c("DTXSID_BAD", "DTXSID1"))),
    "DTXSID_BAD"
  )
  expect_equal(result$child, "DTXSID2")
})
