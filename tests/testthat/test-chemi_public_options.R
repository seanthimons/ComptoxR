test_that("assay listing retains the exact GET route and query options", {
  captured <- NULL
  testthat::local_mocked_bindings(.ct_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, .package = "ComptoxR")
  expect_identical(chemi_toxprints_assays(category = "category", label = "label"), list(result = "unchanged"))
  expect_identical(captured$method, "GET")
  expect_identical(captured$path, "/api/toxprints/assays")
  expect_identical(captured$query, list(category = "category", label = "label"))
  expect_identical(captured$server_resolver$key, "chemi_burl")
  chemi_toxprints_assays()
  expect_identical(captured$query, list(category = NULL, label = NULL))
})
