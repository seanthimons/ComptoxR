# Tests for genra_predict() and related functions
# Integration tests with VCR cassettes

# Helper to check if cassette exists (skip recording tests if API unavailable)
cassette_exists <- function(name) {
  cassette_dir <- here::here("tests/testthat/fixtures")
  file.exists(file.path(cassette_dir, paste0(name, ".yml")))
}

# --- genra_get_tox_data tests ---

test_that("genra_get_tox_data returns expected structure", {
  vcr::use_cassette("genra_get_tox_data_basic", {
    result <- genra_get_tox_data("DTXSID7020182")
  })

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("dtxsid", "activity", "n_records"))
  expect_equal(nrow(result), 1)
  expect_equal(result$dtxsid, "DTXSID7020182")
})

test_that("genra_get_tox_data handles multiple DTXSIDs", {
  vcr::use_cassette("genra_get_tox_data_multiple", {
    result <- genra_get_tox_data(c("DTXSID7020182", "DTXSID3020630"))
  })

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(c("DTXSID7020182", "DTXSID3020630") %in% result$dtxsid))
})

test_that("genra_get_tox_data handles empty input", {
  result <- genra_get_tox_data(character(0))

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_named(result, c("dtxsid", "activity", "n_records"))
})

test_that("genra_get_tox_data includes chemicals with no data as NA", {
  vcr::use_cassette("genra_get_tox_data_missing", {
    # Use a real DTXSID that might have limited data
    result <- genra_get_tox_data(c("DTXSID7020182", "DTXSID00000001"))
  })

  expect_equal(nrow(result), 2)
  # The fake DTXSID should have NA activity and 0 records
  fake_row <- result[result$dtxsid == "DTXSID00000001", ]
  expect_equal(fake_row$n_records, 0L)
})

# --- genra_predict tests ---

test_that("genra_predict returns expected structure", {
  skip_if_not(cassette_exists("genra_predict_basic"), "Cassette not recorded (ct_similar API required)")
  vcr::use_cassette("genra_predict_basic", {
    result <- genra_predict("DTXSID7020182", k = 5, n_permutations = 10)
  })

  expect_s3_class(result, "genra_prediction")
  expect_named(result, c(
    "target", "prediction", "predicted_class", "auc", "p_value",
    "threshold", "n_analogues", "n_analogues_found", "analogues", "parameters"
  ))
  expect_equal(result$target, "DTXSID7020182")
  expect_true(result$predicted_class %in% c("active", "inactive", "uncertain"))
})

test_that("genra_predict validates target input", {
  expect_error(genra_predict(c("DTXSID1", "DTXSID2")), "single DTXSID")
  expect_error(genra_predict(123), "single DTXSID")
  expect_error(genra_predict("CAS123456"), "must be a valid DTXSID")
})

test_that("genra_predict validates k parameter", {
  expect_error(genra_predict("DTXSID7020182", k = 0), ">= 1")
  expect_error(genra_predict("DTXSID7020182", k = -1), ">= 1")
})

test_that("genra_predict validates min_similarity parameter", {
  expect_error(genra_predict("DTXSID7020182", min_similarity = -0.1), "between 0 and 1")
  expect_error(genra_predict("DTXSID7020182", min_similarity = 1.5), "between 0 and 1")
})

test_that("genra_predict analogues tibble has expected columns", {
  skip_if_not(cassette_exists("genra_predict_analogues"), "Cassette not recorded (ct_similar API required)")
  vcr::use_cassette("genra_predict_analogues", {
    result <- genra_predict("DTXSID7020182", k = 5, n_permutations = 10)
  })

  expect_s3_class(result$analogues, "tbl_df")
  expect_true(all(c("dtxsid", "similarity", "activity", "n_records") %in% names(result$analogues)))
})

test_that("genra_predict respects k parameter", {
  skip_if_not(cassette_exists("genra_predict_k_limit"), "Cassette not recorded (ct_similar API required)")
  vcr::use_cassette("genra_predict_k_limit", {
    result <- genra_predict("DTXSID7020182", k = 3, n_permutations = 10)
  })

  expect_lte(nrow(result$analogues), 3)
})

test_that("genra_predict handles no analogues gracefully", {
  skip_if_not(cassette_exists("genra_predict_no_analogues"), "Cassette not recorded (ct_similar API required)")
  vcr::use_cassette("genra_predict_no_analogues", {
    # Use very high similarity threshold that likely won't find analogues
    result <- genra_predict("DTXSID7020182", min_similarity = 0.99, n_permutations = 10)
  })

  expect_equal(result$predicted_class, "uncertain")
  expect_true(is.na(result$prediction))
})

test_that("genra_predict parameters are stored correctly", {
  skip_if_not(cassette_exists("genra_predict_params"), "Cassette not recorded (ct_similar API required)")
  vcr::use_cassette("genra_predict_params", {
    result <- genra_predict(
      "DTXSID7020182",
      k = 8,
      min_similarity = 0.6,
      study_filter = "chronic",
      n_permutations = 50
    )
  })

  expect_equal(result$parameters$k, 8L)
  expect_equal(result$parameters$min_similarity, 0.6)
  expect_equal(result$parameters$study_filter, "chronic")
  expect_equal(result$parameters$n_permutations, 50L)
})

# --- print method tests ---

test_that("print.genra_prediction works without error", {
  skip_if_not(cassette_exists("genra_predict_print"), "Cassette not recorded (ct_similar API required)")
  vcr::use_cassette("genra_predict_print", {
    result <- genra_predict("DTXSID7020182", k = 5, n_permutations = 10)
  })

  expect_output(print(result), "GenRA Read-Across Prediction")
  expect_output(print(result), "DTXSID7020182")
})

test_that("print.genra_prediction returns invisible object", {
  skip_if_not(cassette_exists("genra_predict_print_invisible"), "Cassette not recorded (ct_similar API required)")
  vcr::use_cassette("genra_predict_print_invisible", {
    result <- genra_predict("DTXSID7020182", k = 5, n_permutations = 10)
  })

  returned <- withVisible(print(result))
  expect_false(returned$visible)
  expect_identical(returned$value, result)
})
