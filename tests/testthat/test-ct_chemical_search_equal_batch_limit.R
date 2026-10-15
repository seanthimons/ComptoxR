test_that("exact-search bulk preserves its batch-limit fallback and override", {
  captured <- NULL
  testthat::local_mocked_bindings(
    generic_request = function(...) {
      captured <<- list(...)
      NULL
    },
    .package = "ComptoxR"
  )
  withr::local_envvar(batch_limit = NA_character_)
  ct_chemical_search_equal_bulk("50-00-0")
  expect_identical(captured$batch_limit, 1000)
  expect_identical(captured$body_type, "raw_text")
  Sys.setenv(batch_limit = "2")
  ct_chemical_search_equal_bulk("50-00-0")
  expect_identical(captured$batch_limit, 2)
})
