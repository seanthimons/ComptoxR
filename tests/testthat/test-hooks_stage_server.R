# Tests for the non-production server-swap hook (R/hooks_stage_server.R).
# enforce_stage_server reads the per-function `endpoint_stage` from the loaded
# hook_config and redirects staging/development endpoints to the correct server.

test_that("enforce_stage_server redirects a staging endpoint to the staging server", {
  # chemi_opera is wired with `endpoint_stage: staging` in inst/hook_config.yml.
  data <- list(fn_name = "chemi_opera", params = list(server = "chemi_burl"))
  expect_warning(enforce_stage_server(data), "staging")
  out <- suppressWarnings(enforce_stage_server(data))
  expect_identical(out$params$server, chemi_server(2, url_only = TRUE))
})

test_that("enforce_stage_server leaves a function without an endpoint_stage unchanged", {
  # chemi_hazard is hook-owned but carries no endpoint_stage (it is public).
  data <- list(fn_name = "chemi_hazard", params = list(server = "chemi_burl"))
  out <- enforce_stage_server(data)
  expect_identical(out$params$server, "chemi_burl")
})

test_that("enforce_stage_server leaves an unconfigured function unchanged", {
  data <- list(fn_name = "not_a_real_function", params = list(server = "chemi_burl"))
  out <- enforce_stage_server(data)
  expect_identical(out$params$server, "chemi_burl")
})
