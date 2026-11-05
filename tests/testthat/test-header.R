header_results <- function() {
  list(
    .sitrep_summary(
      "CompTox Dashboard API",
      list(
        latency = 0.1,
        endpoints = tibble::tibble(name = "chemical", status = "OK", message = "HTTP 200")
      )
    ),
    .sitrep_summary(
      "Cheminformatics API",
      list(
        latency = 0.2,
        endpoints = tibble::tibble(
          name = c("rdkit", "alerts", "services"),
          status = c("OK", "WARNING", "ERROR"),
          message = c("HTTP 200", "HTTP 502", "Connection, TLS, or timeout failure")
        )
      ),
      endpoint_list = list(status = "ERROR", message = "HTTP 503"),
      source = "shipped"
    )
  )
}

test_that("header is compact and identifies failed checks without duplicating databases", {
  withr::local_options(list(ComptoxR.run_verbose = TRUE, cli.width = 120L))
  withr::local_envvar(c(ctx_api_key = "secret-never-print", batch_limit = "200"))
  path <- withr::local_tempfile()
  writeLines("local database", path)
  missing <- paste0(path, "-missing")
  checks <- 0L
  testthat::local_mocked_bindings(
    .sitrep_checks = function() {
      checks <<- checks + 1L
      header_results()
    },
    dss_path = function() path,
    eco_path = function() path,
    toxval_path = function() missing,
    .eco_get_con = function(...) stop("Header must not open databases"),
    .tox_get_con = function(...) stop("Header must not open databases"),
    .package = "ComptoxR"
  )
  output <- capture.output(.header(), type = "message")
  text <- paste(output, collapse = "\n")
  expect_identical(checks, 1L)
  expect_match(text, "ComptoxR 4", fixed = TRUE)
  expect_match(text, "Verbose: TRUE | Batch limit: 200", fixed = TRUE)
  expect_match(text, "CompTox Dashboard API: OK (1/1 checks OK, 100ms)", fixed = TRUE)
  expect_match(text, "Cheminformatics API: WARNING (1/3 checks OK, 200ms)", fixed = TRUE)
  expect_match(text, "Endpoint list: HTTP 503; using shipped probes", fixed = TRUE)
  expect_match(text, "alerts (HTTP 502)", fixed = TRUE)
  expect_match(text, "services (Connection, TLS, or timeout failure)", fixed = TRUE)
  expect_false(grepl("rdkit", text, fixed = TRUE))
  expect_identical(sum(grepl("Local databases", output, fixed = TRUE)), 1L)
  expect_identical(sum(grepl("DSSTox:", output, fixed = TRUE)), 1L)
  expect_match(text, "ToxValDB: not installed; run `toxval_install()`", fixed = TRUE)
  expect_match(text, "CompTox API key: SET", fixed = TRUE)
  expect_match(text, "ComptoxR_package_sitrep()", fixed = TRUE)
  expect_false(grepl("secret-never-print", text, fixed = TRUE))
  expect_false(grepl(path, text, fixed = TRUE))
  expect_false(grepl("Built on:", text, fixed = TRUE))
})

test_that("compact startup remains opt-in and suppressible", {
  withr::local_envvar(R_DEVTOOLS_LOAD = "")
  withr::local_options(ComptoxR.run_verbose = FALSE)
  calls <- 0L
  testthat::local_mocked_bindings(
    .sitrep_checks = function() {
      calls <<- calls + 1L
      header_results()
    },
    dss_path = function() tempfile(),
    eco_path = function() tempfile(),
    toxval_path = function() tempfile(),
    .package = "ComptoxR"
  )
  attach <- getFromNamespace(".onAttach", "ComptoxR")
  expect_message(attach("", "ComptoxR"), NA)
  expect_identical(calls, 0L)
  options(ComptoxR.run_verbose = TRUE)
  expect_message(suppressPackageStartupMessages(attach("", "ComptoxR")), NA)
  expect_identical(calls, 1L)
})
