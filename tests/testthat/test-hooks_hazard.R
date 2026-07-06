if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

mock_chemi_hazard_response <- function(wrapped = TRUE) {
  report <- list(
    hazardChemicals = list(
      list(
        chemicalId = "DTXSID-A",
        chemical = list(
          sid = "DTXSID-A",
          casrn = "50-00-0",
          name = "Chemical A"
        ),
        scores = list(
          list(
            hazardId = "acuteMammalianOral",
            hazardName = "Acute mammalian oral",
            finalScore = "L",
            finalAuthority = "QSAR Model",
            finalScoreSource = "TEST",
            records = list(
              list(
                name = "Chemical A record 1",
                source = "Source A",
                sourceOriginal = "Original A",
                listType = "QSAR Model",
                score = "L",
                category = "Category A",
                hazardCode = "H300",
                hazardStatement = "Fatal if swallowed",
                rationale = "Model rationale",
                route = "oral",
                valueMass = 100,
                valueMassUnits = "mg/kg",
                valueMassOperator = "<",
                valueActive = TRUE,
                duration = "24",
                durationUnits = "h",
                effect = "effect A",
                url = "https://example.test/a",
                longRef = "Long reference A",
                testOrganism = "rat",
                testType = "acute",
                toxvalID = "TV-A",
                CAS = "50-00-0"
              ),
              list(
                name = "Chemical A record 2",
                source = "Source B",
                listType = "QSAR Model",
                score = "L",
                cas = "50-00-0"
              )
            )
          ),
          list(
            hazardId = "developmental",
            hazardName = "Developmental",
            finalScore = "M",
            finalAuthority = "Authoritative",
            finalScoreSource = "ToxValDB",
            records = list()
          ),
          list(
            hazardId = "acuteMammalianOral",
            hazardName = "Acute mammalian oral",
            finalScore = "H",
            finalAuthority = "Authoritative",
            finalScoreSource = "ToxValDB",
            records = list(
              list(
                name = "Chemical A authoritative record",
                source = "ToxValDB",
                listType = "Authoritative",
                score = "H",
                CAS = "50-00-0"
              )
            )
          )
        )
      ),
      list(
        chemicalId = "DTXSID-B",
        chemical = list(
          chemId = "DTXSID-B",
          casrn = "67-56-1",
          name = "Chemical B"
        ),
        scores = list(
          list(
            hazardId = "endocrine",
            hazardName = "Endocrine",
            finalScore = "ND",
            finalAuthority = "Screening",
            finalScoreSource = "List",
            records = list()
          ),
          list(
            hazardId = "acuteMammalianOral",
            hazardName = "Acute mammalian oral",
            finalScore = "VH",
            finalAuthority = "Screening",
            finalScoreSource = "List",
            records = list(
              list(
                name = "Chemical B record",
                source = "Screening list",
                listType = "Screening",
                score = "VH",
                CAS = "67-56-1"
              )
            )
          )
        )
      )
    )
  )

  if (isTRUE(wrapped)) {
    list(report)
  } else {
    report
  }
}

test_that("format_chemi_hazard_result returns raw response unchanged", {
  hook <- get("format_chemi_hazard_result", envir = asNamespace("ComptoxR"))
  raw <- mock_chemi_hazard_response()

  result <- hook(list(result = raw, params = list(format = "raw")))

  expect_identical(result, raw)
})

test_that("format_chemi_hazard_result creates tidy long hazard rows", {
  hook <- get("format_chemi_hazard_result", envir = asNamespace("ComptoxR"))

  result <- hook(list(result = mock_chemi_hazard_response(), params = list(format = "tidy")))

  expect_s3_class(result, "tbl_df")
  expect_named(result, get("chemi_hazard_tidy_columns", envir = asNamespace("ComptoxR"))())
  expect_equal(nrow(result), 6L)
  expect_equal(unique(result$dtxsid), c("DTXSID-A", "DTXSID-B"))
  expect_true("<i>L</i>" %in% result$display_score)
  expect_true("<b>M</b>" %in% result$display_score)
  expect_true("VH" %in% result$display_score)

  developmental <- result[result$dtxsid == "DTXSID-A" & result$hazard_id == "developmental", ]
  expect_equal(nrow(developmental), 1L)
  expect_true(is.na(developmental$record_name))
  expect_equal(developmental$final_score, "M")

  oral_records <- result[result$dtxsid == "DTXSID-A" & result$hazard_id == "acuteMammalianOral", ]
  expect_equal(nrow(oral_records), 3L)
  expect_equal(oral_records$casrn, rep("50-00-0", 3L))
  expect_true("50-00-0" %in% oral_records$record_cas)
})

test_that("format_chemi_hazard_result creates compact wide hazard rows", {
  hook <- get("format_chemi_hazard_result", envir = asNamespace("ComptoxR"))

  result <- hook(list(result = mock_chemi_hazard_response(), params = list(format = "compact")))
  endpoints <- get("chemi_hazard_endpoint_order", envir = asNamespace("ComptoxR"))()

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("dtxsid", "casrn", "name", "n_hazards", endpoints))
  expect_equal(nrow(result), 2L)
  expect_equal(result$n_hazards, c(2L, 2L))
  expect_equal(result$acuteMammalianOral[result$dtxsid == "DTXSID-A"], "<b>H</b>")
  expect_equal(result$developmental[result$dtxsid == "DTXSID-A"], "<b>M</b>")
  expect_equal(result$acuteMammalianOral[result$dtxsid == "DTXSID-B"], "VH")
  expect_equal(result$endocrine[result$dtxsid == "DTXSID-B"], "ND")
  expect_equal(
    names(result)[seq.int(5L, length.out = length(endpoints))],
    endpoints
  )
})

test_that("format_chemi_hazard_result validates format values", {
  hook <- get("format_chemi_hazard_result", envir = asNamespace("ComptoxR"))

  expect_error(
    hook(list(result = mock_chemi_hazard_response(), params = list(format = "wide"))),
    "should be one of"
  )
})

test_that("chemi_hazard post-processes mocked generic_request output", {
  calls <- list()

  local_mocked_bindings(
    generic_request = function(...) {
      captured <- list(...)
      calls[[length(calls) + 1L]] <<- captured
      mock_chemi_hazard_response()
    },
    .package = "ComptoxR"
  )

  result <- ComptoxR::chemi_hazard(query = "DTXSID-A", format = "tidy")

  expect_gt(length(calls), 0L)
  expect_equal(calls[[1L]]$endpoint, "hazard")
  expect_false(calls[[1L]]$tidy)
  expect_equal(result$dtxsid[1L], "DTXSID-A")
  expect_equal(nrow(result), 6L)
})

test_that("chemi_hazard_bulk keeps resolver pre-hook and post-processes output", {
  resolver_called <- FALSE
  chemi_called <- FALSE

  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType = "AnyId", tidy = FALSE, ...) {
      resolver_called <<- TRUE
      expect_equal(ids, "50-00-0")
      expect_equal(idsType, "AnyId")
      expect_false(tidy)
      list(list(
        result = "FOUND",
        chemical = list(
          chemId = "DTXSID-A",
          casrn = "50-00-0",
          name = "Chemical A",
          canonicalSmiles = "C=O"
        )
      ))
    },
    generic_chemi_request = function(...) {
      chemi_called <<- TRUE
      captured <- list(...)
      expect_null(captured$query)
      expect_equal(captured$endpoint, "hazard")
      expect_false(captured$tidy)
      expect_length(captured$chemicals, 1L)
      mock_chemi_hazard_response(wrapped = FALSE)
    },
    .package = "ComptoxR"
  )

  result <- ComptoxR::chemi_hazard_bulk(query = "50-00-0", format = "compact")

  expect_true(resolver_called)
  expect_true(chemi_called)
  expect_equal(nrow(result), 2L)
  expect_equal(result$acuteMammalianOral[result$dtxsid == "DTXSID-A"], "<b>H</b>")
})
