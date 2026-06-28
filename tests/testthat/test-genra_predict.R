# Tests for GenRA prediction helpers that require bespoke offline assertions.

mock_toxval_records <- function(dtxsids) {
  tibble::tibble(
    dtxsidName = c("DTXSID7020182", "DTXSID3020630", "DTXSID3020630"),
    toxvalType = c("LOAEL", "NOAEL", "NOEC"),
    studyType = c("chronic", "acute", "developmental")
  )
}

test_that("genra_get_tox_data parses ToxVal activity offline", {
  testthat::local_mocked_bindings(
    ct_hazard_toxval_search_bulk = mock_toxval_records,
    .package = "ComptoxR"
  )

  result <- genra_get_tox_data(c("DTXSID7020182", "DTXSID3020630", "DTXSID00000001"))

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("dtxsid", "activity", "n_records"))
  expect_equal(nrow(result), 3)
  expect_equal(result$activity[result$dtxsid == "DTXSID7020182"], 1L)
  expect_equal(result$activity[result$dtxsid == "DTXSID3020630"], 0L)
  expect_true(is.na(result$activity[result$dtxsid == "DTXSID00000001"]))
  expect_equal(result$n_records[result$dtxsid == "DTXSID00000001"], 0L)
})

test_that("genra_get_tox_data handles empty input without calling API helpers", {
  result <- genra_get_tox_data(character(0))

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("dtxsid", "activity", "n_records"))
  expect_equal(nrow(result), 0)
})

test_that("genra_get_tox_data applies study filters before activity classification", {
  testthat::local_mocked_bindings(
    ct_hazard_toxval_search_bulk = mock_toxval_records,
    .package = "ComptoxR"
  )

  result <- genra_get_tox_data("DTXSID3020630", study_filter = "developmental")

  expect_equal(result$activity, 0L)
  expect_equal(result$n_records, 1L)
})

test_that("genra_predict validates inputs before API-dependent work", {
  expect_error(genra_predict(c("DTXSID1", "DTXSID2")), "single DTXSID")
  expect_error(genra_predict(123), "single DTXSID")
  expect_error(genra_predict("CAS123456"), "must be a valid DTXSID")
  expect_error(genra_predict("DTXSID7020182", k = 0), ">= 1")
  expect_error(genra_predict("DTXSID7020182", k = -1), ">= 1")
  expect_error(genra_predict("DTXSID7020182", min_similarity = -0.1), "between 0 and 1")
  expect_error(genra_predict("DTXSID7020182", min_similarity = 1.5), "between 0 and 1")
})

test_that("genra_predict builds a prediction object from mocked analogues and activity", {
  testthat::local_mocked_bindings(
    ct_similar = function(query, similarity) {
      expect_equal(query, "DTXSID7020182")
      expect_equal(similarity, 0.5)
      tibble::tibble(
        relatedSubstanceDTXSID = c("DTXSID1", "DTXSID2", "DTXSID3"),
        structuralSimilarity = c(0.9, 0.8, 0.7)
      )
    },
    genra_get_tox_data = function(dtxsids, study_filter = NULL) {
      expect_equal(dtxsids, c("DTXSID1", "DTXSID2"))
      expect_equal(study_filter, "chronic")
      tibble::tibble(
        dtxsid = dtxsids,
        activity = c(1L, 0L),
        n_records = c(2L, 1L)
      )
    },
    .package = "ComptoxR"
  )

  set.seed(1)
  result <- suppressMessages(genra_predict(
    "DTXSID7020182",
    k = 2,
    min_similarity = 0.5,
    study_filter = "chronic",
    n_permutations = 5
  ))

  expect_s3_class(result, "genra_prediction")
  expect_named(
    result,
    c(
      "target",
      "prediction",
      "predicted_class",
      "auc",
      "p_value",
      "threshold",
      "n_analogues",
      "n_analogues_found",
      "analogues",
      "parameters"
    )
  )
  expect_equal(result$target, "DTXSID7020182")
  expect_equal(result$n_analogues_found, 2L)
  expect_equal(result$n_analogues, 2L)
  expect_equal(result$analogues$dtxsid, c("DTXSID1", "DTXSID2"))
  expect_equal(result$parameters$k, 2L)
  expect_equal(result$parameters$study_filter, "chronic")
  expect_true(result$predicted_class %in% c("active", "inactive", "uncertain"))
})

test_that("genra_predict returns uncertain result when no analogues are found", {
  testthat::local_mocked_bindings(
    ct_similar = function(query, similarity) {
      tibble::tibble(
        relatedSubstanceDTXSID = character(),
        structuralSimilarity = numeric()
      )
    },
    .package = "ComptoxR"
  )

  result <- suppressWarnings(suppressMessages(genra_predict("DTXSID7020182", n_permutations = 5)))

  expect_s3_class(result, "genra_prediction")
  expect_equal(result$predicted_class, "uncertain")
  expect_true(is.na(result$prediction))
  expect_equal(result$n_analogues, 0L)
  expect_equal(nrow(result$analogues), 0)
})

test_that("genra_predict keeps analogue rows when no activity data are available", {
  testthat::local_mocked_bindings(
    ct_similar = function(query, similarity) {
      tibble::tibble(
        relatedSubstanceDTXSID = c("DTXSID1", "DTXSID2"),
        structuralSimilarity = c(0.9, 0.8)
      )
    },
    genra_get_tox_data = function(dtxsids, study_filter = NULL) {
      tibble::tibble(
        dtxsid = dtxsids,
        activity = c(NA_integer_, NA_integer_),
        n_records = c(0L, 0L)
      )
    },
    .package = "ComptoxR"
  )

  result <- suppressWarnings(suppressMessages(genra_predict("DTXSID7020182", k = 2, n_permutations = 5)))

  expect_equal(result$predicted_class, "uncertain")
  expect_true(is.na(result$prediction))
  expect_equal(result$n_analogues_found, 2L)
  expect_equal(result$n_analogues, 0L)
  expect_equal(nrow(result$analogues), 2)
})

test_that("print.genra_prediction emits summary and returns invisibly", {
  prediction <- structure(
    list(
      target = "DTXSID7020182",
      prediction = 0.75,
      predicted_class = "active",
      auc = 0.8,
      p_value = 0.2,
      threshold = 0.5,
      n_analogues = 2L,
      n_analogues_found = 3L,
      analogues = tibble::tibble(
        dtxsid = c("DTXSID1", "DTXSID2"),
        similarity = c(0.9, 0.8),
        activity = c(1L, 0L),
        n_records = c(2L, 1L)
      ),
      parameters = list(
        k = 2L,
        min_similarity = 0.5,
        study_filter = NULL,
        n_permutations = 5L
      )
    ),
    class = "genra_prediction"
  )

  output <- capture.output(print(prediction), type = "message")
  expect_match(paste(output, collapse = "\n"), "GenRA Read-Across Prediction")
  expect_match(paste(output, collapse = "\n"), "DTXSID7020182")

  returned <- NULL
  capture.output(returned <- withVisible(print(prediction)), type = "message")
  expect_false(returned$visible)
  expect_identical(returned$value, prediction)
})
