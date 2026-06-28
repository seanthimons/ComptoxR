# Handwritten tests for cc_detail response shaping.
#
# The generated contract (mocking generic_cc_request) only asserts the request
# boundary (endpoint/method/cas_rn pass-through). It cannot feed a count/results
# fixture, so the post-processing branches the wrapper owns are untested here:
#     - count <= 1: pluck results[[1]], drop the "images" element, return as_tibble()
#     - count  > 1: emit a cli alert and return the raw result list unchanged.

test_that("cc_detail shapes a single result into an images-free tibble", {
  fixture <- list(
    count = 1L,
    results = list(
      list(casrn = "123-91-1", preferredName = "1,4-Dioxane", images = "<svg/>")
    )
  )

  testthat::local_mocked_bindings(
    generic_cc_request = function(...) fixture,
    .package = "ComptoxR"
  )

  result <- cc_detail(cas_rn = "123-91-1")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_false("images" %in% names(result))
  expect_equal(result$casrn, "123-91-1")
  expect_equal(result$preferredName, "1,4-Dioxane")
})

test_that("cc_detail alerts and returns the raw list when multiple results return", {
  fixture <- list(
    count = 2L,
    results = list(
      list(casrn = "1"),
      list(casrn = "2")
    )
  )

  testthat::local_mocked_bindings(
    generic_cc_request = function(...) fixture,
    .package = "ComptoxR"
  )

  expect_message(
    result <- cc_detail(cas_rn = "123-91-1"),
    regexp = "Multiple results"
  )

  # Raw, unshaped list passes through unchanged (no pluck / tibble coercion).
  expect_identical(result, fixture)
})
