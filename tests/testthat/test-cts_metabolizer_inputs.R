test_that("CTS sends an empty JSON object to fetch the input template", {
  local_mocked_bindings(
    req_perform = function(req, ...) {
      expect_identical(req$method, "POST")
      expect_identical(req$url, "https://qed.epa.gov/cts/rest/metabolizer/inputs")
      expect_identical(as.character(jsonlite::toJSON(req$body$data, auto_unbox = TRUE)), "{}")
      httr2::response(
        status_code = 200L,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"metaInfo":{},"inputs":{"structure":"","generationLimit":1}}')
      )
    },
    .package = "httr2"
  )

  expect_identical(cts_metabolizer_inputs(list())$inputs$structure, "")
})
