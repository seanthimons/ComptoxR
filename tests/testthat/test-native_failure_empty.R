test_that("dropped HTTP failures retain table shape before client formatting", {
  withr::local_envvar(ctx_api_key = "local-failure-key")
  local_mocked_bindings(req_perform = function(req, ...) {
    httr2::response(status_code = 404L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"error":"not found"}'))
  }, .package = "httr2")
  for (fn in list(ct_chemical_detail_search_bulk, ct_chemical_detail_search_by_dtxcid, chemi_classyfire)) {
    expect_warning(result <- fn("bad"), "failed")
    expect_s3_class(result, "tbl_df")
    expect_identical(nrow(result), 0L)
  }
  # Exact failure-attribute parity remains blocked by Specmill #142.
})

test_that("a dropped failed item preserves the successful table rows", {
  local_mocked_bindings(req_perform = function(req, ...) {
    failed <- endsWith(req$url, "/bad")
    httr2::response(status_code = if (failed) 404L else 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw(if (failed) '{"error":"not found"}' else '{"kingdom":"Organic"}'))
  }, .package = "httr2")
  expect_warning(result <- chemi_classyfire(c("good", "bad")), "failed")
  expect_s3_class(result, "tbl_df")
  expect_identical(result$dtxsid, "good")
  expect_identical(nrow(result), 1L)
})
