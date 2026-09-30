test_that("public options reach the chemi helper without replacing sibling fields", {
  captured <- NULL
  testthat::local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(result = "unchanged")
    },
    .package = "ComptoxR"
  )
  for (name in c("chemi_stdizer_records", "chemi_toxprints_assays_bulk")) {
    fun <- getExportedValue("ComptoxR", name)
    inputs <- if (name == "chemi_stdizer_records") {
      list(full = "pilot-1", records = list(list(sid = "record-1")))
    } else {
      list(acl = "pilot-1", actives = 0, category = "category", chemicals = list(list(sid = "record-1")),
        id = "id", labels = c("one", "two"), metrics = list(score = 0), name = "assay", total = 0)
    }
    siblings <- inputs[-1L]
    for (value in list(NULL, list(), list(flag = FALSE, count = 0, nested = list(label = "caller")), FALSE, 0)) {
      supplied <- inputs
      supplied["options"] <- list(value)
      expect_identical(do.call(fun, supplied), list(result = "unchanged"))
      expected_options <- siblings
      if (!is.null(value)) expected_options <- append(expected_options, list(options = value), after = if (name == "chemi_stdizer_records") 0L else length(siblings) - 1L)
      expect_identical(captured$options, expected_options)
      expect_identical(captured$query, "pilot-1")
      expect_identical(captured$endpoint, if (name == "chemi_stdizer_records") "stdizer/records" else "toxprints/assays")
      expect_identical(captured$tidy, FALSE)
    }
    do.call(fun, inputs)
    expect_identical(captured$options, siblings)
    fun()
    expect_identical(captured$options, list())
  }
})

test_that("assay listing retains the exact GET route and query options", {
  captured <- NULL
  testthat::local_mocked_bindings(
    generic_request = function(...) {
      captured <<- list(...)
      list(result = "unchanged")
    },
    .package = "ComptoxR"
  )
  expect_identical(chemi_toxprints_assays(category = "category", label = "label"), list(result = "unchanged"))
  expect_identical(captured, list(endpoint = "toxprints/assays", method = "GET", batch_limit = 0,
    server = "chemi_burl", auth = FALSE, tidy = FALSE, options = list(category = "category", label = "label")))
  chemi_toxprints_assays()
  expect_identical(captured$options, list())
})
