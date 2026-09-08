probe_script <- testthat::test_path("..", "..", "dev", "probe_api_compatibility.R")
if (!file.exists(probe_script)) {
  testthat::skip("Maintainer-only test requires dev/probe_api_compatibility.R")
}
source(probe_script)

test_that("live probes use the effective configured URLs without changing the session", {
  probe <- new.env(parent = environment())
  sys.source(probe_script, envir = probe)
  testthat::local_mocked_bindings(load_all = function(...) invisible(NULL), .package = "pkgload")
  withr::local_envvar(c(CTX_API_KEY = "test-only", chemi_burl = "https://example.invalid/chemi"))
  withr::local_options(list(ComptoxR.ctx_burl = "https://example.invalid/ctx"))
  calls <- character()
  probe$probe_http <- function(base_url, ...) {
    calls <<- c(calls, base_url)
    probe_response(FALSE)
  }
  probe$chemi_descriptors_bulk <- function(...) data.frame()
  probe$chemi_webtest_predict_bulk <- function(...) data.frame()
  result <- probe$run_compatibility_probe()
  expect_identical(unique(calls), c("https://example.invalid/chemi", "https://example.invalid/ctx"))
  expect_true(all(result$environment == "configured"))
  expect_identical(Sys.getenv("chemi_burl"), "https://example.invalid/chemi")
})

test_that("probe evaluator checks descriptor alignment and metadata", {
  descriptor <- probe_response(
    TRUE,
    list(
      headers = c("a", "b"),
      chemicals = list(list(descriptors = c(1, 2)))
    ),
    200L
  )
  mismatch <- descriptor
  mismatch$body$chemicals[[1]]$descriptors <- 1
  metadata <- probe_response(
    TRUE,
    list(descriptors = list(list(name = "RDKit"), list(name = "Mordred"))),
    200L
  )

  expect_true(evaluate_probe("descriptor", descriptor, 2L)$pass)
  expect_false(evaluate_probe("descriptor", mismatch, 2L)$pass)
  expect_true(evaluate_probe("metadata", metadata, c("rdkit", "mordred"))$pass)
})

test_that("probe evaluator detects wrapper drift without network calls", {
  inputs <- c("CCO", "DTXSID7020182", "DTXSID000000000")
  rdkit <- data.frame(
    query = inputs,
    input_index = 1:3,
    status = c("ok", "ok", "error"),
    error = c(NA, NA, "not found"),
    smiles = c("CCO", "CCO", NA),
    inchi = NA_character_,
    inchi_key = NA_character_,
    source_server = "server",
    source_endpoint = "rdkit",
    fallback_used = FALSE,
    stringsAsFactors = FALSE
  )
  for (index in seq_len(1024L)) {
    rdkit[[sprintf("bit_%04d", index)]] <- NA_real_
  }
  webtest <- data.frame(
    query = inputs,
    input_index = 1:3,
    status = c("ok", "ok", "error"),
    endpoint_id = c("LC50", "LC50", NA),
    method = c("consensus", "consensus", NA),
    source_server = "server",
    source_endpoint = "webtest/predict",
    stringsAsFactors = FALSE
  )

  expect_true(evaluate_probe("wrapper_rdkit", rdkit, inputs)$pass)
  expect_true(evaluate_probe("wrapper_webtest", webtest, inputs)$pass)
  webtest$method[[1]] <- "hc"
  expect_false(evaluate_probe("wrapper_webtest", webtest, inputs)$pass)
})

test_that("known direct defects are reported without becoming wrapper failures", {
  result <- probe_case(
    "production",
    "direct",
    "known upstream",
    "http",
    probe_response(FALSE),
    known_issue = TRUE
  )

  expect_identical(result$status, "known_defect")
  expect_false(result$surface == "wrapper" & result$status == "fail")
})
