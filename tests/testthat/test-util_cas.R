test_that("is_cas validates format and check digit", {
  expect_identical(
    is_cas(c("50-00-0", "50-00-1", "7732-18-5", "not-a-casrn", NA, "50000")),
    c(TRUE, FALSE, TRUE, FALSE, NA, FALSE)
  )
  expect_identical(is_cas(character(0)), logical(0))
})

test_that("as_cas normalizes padded, unhyphenated and noisy input", {
  expect_identical(
    as_cas(c("0050-00-0", "CAS: 7732-18-5", "50000", "50-00-1", NA, "NOCAS_1355346")),
    c("50-00-0", "7732-18-5", "50-00-0", NA, NA, NA)
  )
})
