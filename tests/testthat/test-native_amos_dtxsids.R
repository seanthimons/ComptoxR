test_that("AMOS DTXSID lookup preserves captured JSON values and singleton arrays", {
  fixture <- readRDS(test_path("fixtures", "native-amos-dtxsids.rds"))
  requests <- list()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"), body = fixture$body)
  }, .package = "httr2")
  expect_identical(chemi_amos_dtxsids("DTXSID7020182"), fixture$result)
  expect_identical(requests[[1L]]$body$data$dtxsids, I("DTXSID7020182"))
  expect_identical(chemi_amos_dtxsids(c("one", "one", "", NA_character_, "café")),
    fixture$result)
  expect_identical(requests[[2L]]$body$data$dtxsids, I(c("one", "café")))
  expect_error(chemi_amos_dtxsids(), "Supply at least one DTXSID")
  expect_length(requests, 2L)
})
