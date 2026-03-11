library(testthat)
library(ComptoxR)

test_that("clean_unicode handles standard Greek without dots", {
  expect_equal(clean_unicode("\u03b1-Endosulfan"), "alpha-Endosulfan")
  expect_equal(clean_unicode("17\u03b2-Estradiol"), "17beta-Estradiol")
  expect_equal(clean_unicode("\u0393-BHC"), "gamma-BHC")
})

test_that("clean_unicode handles mathematical Greek variants", {
  # Bold alpha (U+1D6C2)
  expect_equal(clean_unicode("\U0001D6C2-Endosulfan"), "alpha-Endosulfan")
  # Italic beta (U+1D6FD)
  expect_equal(clean_unicode("17\U0001D6FD-Estradiol"), "17beta-Estradiol")
  # Bold italic beta (U+1D737)
  expect_equal(clean_unicode("\U0001D737-BHC"), "beta-BHC")
})

test_that("clean_unicode handles lunate/variant symbols", {
  # Lunate epsilon (U+03F5)
  expect_equal(clean_unicode("\u03F5-isomer"), "epsilon-isomer")
  # Script/variant pi (U+03D6)
  expect_equal(clean_unicode("\u03D6-calc"), "pi-calc")
})

test_that("clean_unicode removes metadata symbols", {
  expect_equal(clean_unicode("Chemical\u2122"), "Chemical")
  expect_equal(clean_unicode("Compound\u00ae"), "Compound")
  expect_equal(clean_unicode("Copyright\u00a9"), "Copyright")
})

test_that("clean_unicode handles math and units", {
  expect_equal(clean_unicode("Concentration \u2265 10 \u03bcg/L"), "Concentration >= 10 mug/L")
  expect_equal(clean_unicode("100 \u00b1 5"), "100 +/- 5")
})
