# Tests for chemi_predict
# Handwritten: chemi_predict hand-builds an httr2 request instead of calling the
# shared generic_* helpers, so the generated contract tests cannot cover its
# preprocessing branches or request/response path. chemi_predict uses bare
# (import(httr2)) verbs, so the httr2 functions are mocked in the ComptoxR
# namespace; nothing hits the network.

if (!exists("generated_contract_ensure_package", mode = "function")) {
  helper <- file.path("tests", "testthat", "helper-generated-contracts.R")
  if (!file.exists(helper)) {
    helper <- "helper-generated-contracts.R"
  }
  if (file.exists(helper)) {
    source(helper)
  }
}
if (exists("generated_contract_ensure_package", mode = "function")) {
  generated_contract_ensure_package()
}

# Build a minimal httr2 response with a JSON body.
chemi_predict_mock_response <- function(status, payload) {
  httr2::response(
    status_code = status,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(jsonlite::toJSON(payload, auto_unbox = TRUE))
  )
}

test_that("chemi_predict aborts when resolution returns no chemicals", {
  testthat::local_mocked_bindings(
    chemi_resolver_lookup = function(query, ...) character(0),
    # req_perform must never run; if it does the abort guard failed.
    req_perform = function(req, ...) stop("network should not be reached"),
    .package = "ComptoxR"
  )

  expect_error(
    suppressMessages(ComptoxR::chemi_predict("aspirin")),
    "No chemicals resolved for the given query."
  )
})

test_that("chemi_predict warns on an invalid report and coerces it to JSON", {
  captured <- NULL
  testthat::local_mocked_bindings(
    chemi_resolver_lookup = function(query, ...) c("CCCC"),
    req_perform = function(req, ...) {
      captured <<- req
      chemi_predict_mock_response(200, list(ok = TRUE))
    },
    .package = "ComptoxR"
  )

  expect_warning(
    suppressMessages(ComptoxR::chemi_predict("aspirin", report = "BOGUS")),
    "Invalid report format"
  )

  # The bad report must be replaced with JSON before the body is built.
  expect_equal(captured$body$data$report, "JSON")
})

test_that("chemi_predict POSTs to webtest/predict and returns the parsed body unchanged", {
  resolved <- c("CCCC", "CCO")
  response_payload <- list(predictions = list(list(name = "aspirin", value = 1.23)))
  captured <- NULL
  testthat::local_mocked_bindings(
    chemi_resolver_lookup = function(query, ...) resolved,
    req_perform = function(req, ...) {
      captured <<- req
      chemi_predict_mock_response(200, response_payload)
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(ComptoxR::chemi_predict("aspirin", report = "SDF"))

  expect_equal(result, response_payload)
  expect_equal(captured$method, "POST")
  expect_match(captured$url, "webtest/predict")
  expect_equal(captured$body$data$structures, resolved)
  expect_equal(captured$body$data$report, "SDF")
})

test_that("chemi_predict aborts on a >=400 response status", {
  testthat::local_mocked_bindings(
    chemi_resolver_lookup = function(query, ...) c("CCCC"),
    req_perform = function(req, ...) chemi_predict_mock_response(500, list()),
    .package = "ComptoxR"
  )

  expect_error(
    suppressMessages(ComptoxR::chemi_predict("aspirin")),
    "API request failed with status 500"
  )
})
