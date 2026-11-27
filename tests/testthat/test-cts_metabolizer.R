test_that("CTS returns discovery metadata", {
  local_mocked_bindings(
    req_perform = function(req, ...) {
      expect_identical(req$method, "GET")
      expect_identical(req$url, "https://qed.epa.gov/cts/rest/metabolizer")
      httr2::response(
        status_code = 200L,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"metaInfo":{},"links":null}')
      )
    },
    .package = "httr2"
  )

  expect_named(cts_metabolizer(), c("metaInfo", "links"))
})
