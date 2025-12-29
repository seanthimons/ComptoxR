test_that("clean_unicode works for character vectors", {
  # Greek letters
  expect_equal(clean_unicode("17β-Estradiol"), "17.beta.-Estradiol")
  expect_equal(clean_unicode("Δ-9-THC"), ".delta.-9-THC")
  expect_equal(clean_unicode("Striated Muscle [α]"), "Striated Muscle [.alpha.]")
  
  # Math symbols
  expect_equal(clean_unicode("Concentration ≥ 10"), "Concentration >= 10")
  expect_equal(clean_unicode("±5% error"), "+/-5% error")
  
  # Units
  expect_equal(clean_unicode("10 µg/L"), "10 ug/L")
  expect_equal(clean_unicode("Temperature is 25°C"), "Temperature is 25C")
  
  # Accents
  expect_equal(clean_unicode("Methanol p.a. (≥99.9%)"), "Methanol p.a. (>=99.9%)")
})

test_that("clean_unicode works for data frames", {
  df <- data.frame(
    name = c("17β-Estradiol", "α-Pinene"),
    value = c(10, 20),
    stringsAsFactors = FALSE
  )
  
  cleaned <- clean_unicode(df)
  
  expect_equal(cleaned$name[1], "17.beta.-Estradiol")
  expect_equal(cleaned$name[2], ".alpha.-Pinene")
  expect_equal(cleaned$value[1], 10)
})

test_that("check_unhandled flags unknown unicode", {
  # 💩 is \U0001F4A9
  expect_warning(clean_unicode("\U0001F4A9"))
})

test_that("clean_unicode handles NA and factors", {
  expect_equal(clean_unicode(as.character(NA)), as.character(NA))
  
  # Non-character input should be returned as-is
  expect_equal(clean_unicode(123), 123)
})
