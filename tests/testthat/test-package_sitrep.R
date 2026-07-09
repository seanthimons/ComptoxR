# Tests for package_sitrep
# This function generates diagnostic reports

local_sitrep_env <- function() {
  withr::local_envvar(
    c(
      ctx_burl = "",
      chemi_burl = "",
      eco_burl = "",
      toxval_burl = "",
      epi_burl = "",
      np_burl = "",
      pubchem_burl = ""
    ),
    .local_envir = parent.frame()
  )
}

test_that("package_sitrep runs without errors", {
  # Run the function in a temporary directory
  withr::with_tempdir({
    local_sitrep_env()
    result <- ComptoxR_package_sitrep()

    # Check that result is a list
    expect_type(result, "list")

    # Check that expected keys are present
    expect_true("timestamp" %in% names(result))
    expect_true("log_file" %in% names(result))
    expect_true("package_version" %in% names(result))
    expect_true("package_date" %in% names(result))
    expect_true("api_tokens" %in% names(result))
    expect_true("server_paths" %in% names(result))
    expect_true("ping_results" %in% names(result))
    expect_true("local_databases" %in% names(result))

    # Check that log file was created
    expect_true(file.exists(result$log_file))

    # Check that log file contains expected sections
    log_content <- readLines(result$log_file)
    expect_true(any(grepl("PACKAGE VERSION", log_content)))
    expect_true(any(grepl("API TOKENS STATUS", log_content)))
    expect_true(any(grepl("CONFIGURED SERVER PATHS", log_content)))
    expect_true(any(grepl("PING TEST RESULTS", log_content)))
    expect_true(any(grepl("LOCAL DATABASES", log_content)))
  })
})

test_that("package_sitrep creates timestamped log file", {
  withr::with_tempdir({
    local_sitrep_env()
    result <- ComptoxR_package_sitrep()

    # Check log file naming pattern (use basename to handle full paths)
    expect_match(basename(result$log_file), "^comptoxr_sitrep_\\d{8}_\\d{6}\\.log$")
  })
})

test_that("package_sitrep detects API token status correctly", {
  withr::with_tempdir({
    local_sitrep_env()
    # Save original env vars
    orig_ctx <- Sys.getenv("ctx_api_key", unset = NA)
    # Test with no tokens set
    Sys.unsetenv("ctx_api_key")

    result <- ComptoxR_package_sitrep()
    expect_false(result$api_tokens$ctx_api_key)

    # Test with tokens set
    Sys.setenv(ctx_api_key = "test_token_123")

    result <- ComptoxR_package_sitrep()
    expect_true(result$api_tokens$ctx_api_key)

    # Restore original env vars
    if (!is.na(orig_ctx)) Sys.setenv(ctx_api_key = orig_ctx) else Sys.unsetenv("ctx_api_key")
  })
})

test_that("package_sitrep captures server paths", {
  withr::with_tempdir({
    local_sitrep_env()
    result <- ComptoxR_package_sitrep()

    # Check that server_paths is a list
    expect_type(result$server_paths, "list")

    # Check that expected servers are present
    expect_true("CompTox Dashboard API" %in% names(result$server_paths))
    expect_true("Cheminformatics API" %in% names(result$server_paths))
  })
})

test_that("package_sitrep returns ping results", {
  withr::with_tempdir({
    local_sitrep_env()
    result <- ComptoxR_package_sitrep()

    # Check that ping_results is a list
    expect_type(result$ping_results, "list")

    # Each ping result should have required fields
    for (ping_result in result$ping_results) {
      expect_true("name" %in% names(ping_result))
      expect_true("status" %in% names(ping_result))
      expect_true("message" %in% names(ping_result))
      expect_true("latency" %in% names(ping_result))
    }
  })
})

test_that("package_sitrep marks unconfigured servers as SKIPPED", {
  withr::with_tempdir({
    local_sitrep_env()
    result <- ComptoxR_package_sitrep()

    # With all *_burl unset, no network is hit; pings report SKIPPED.
    statuses <- vapply(result$ping_results, function(x) x$status, character(1))
    expect_true(all(statuses == "SKIPPED"))
    expect_true(all(is.na(vapply(
      result$ping_results,
      function(x) x$latency,
      numeric(1)
    ))))
  })
})

# ---- run_debug -------------------------------------------------------------

test_that("run_debug(TRUE) sets run_debug env var to TRUE", {
  withr::local_envvar(run_debug = NA)
  run_debug(TRUE)
  expect_identical(Sys.getenv("run_debug"), "TRUE")
})

test_that("run_debug(FALSE) sets run_debug env var to FALSE", {
  withr::local_envvar(run_debug = NA)
  run_debug(FALSE)
  expect_identical(Sys.getenv("run_debug"), "FALSE")
})

test_that("run_debug with non-logical input warns and defaults to FALSE", {
  withr::local_envvar(run_debug = NA)
  expect_message(run_debug("not-a-logical"), "Invalid debug option")
  expect_identical(Sys.getenv("run_debug"), "FALSE")
})

# ---- run_verbose -----------------------------------------------------------

test_that("run_verbose(TRUE) sets run_verbose env var to TRUE", {
  withr::local_envvar(run_verbose = NA)
  run_verbose(TRUE)
  expect_identical(Sys.getenv("run_verbose"), "TRUE")
})

test_that("run_verbose(FALSE) sets run_verbose env var to FALSE", {
  withr::local_envvar(run_verbose = NA)
  run_verbose(FALSE)
  expect_identical(Sys.getenv("run_verbose"), "FALSE")
})

test_that("run_verbose with non-logical input warns and defaults to FALSE", {
  withr::local_envvar(run_verbose = NA)
  expect_message(run_verbose(42), "Invalid verbose option")
  expect_identical(Sys.getenv("run_verbose"), "FALSE")
})

# ---- batch_limit -----------------------------------------------------------

test_that("batch_limit sets the batch_limit env var to the given numeric", {
  withr::local_envvar(batch_limit = NA)
  batch_limit(50)
  expect_identical(Sys.getenv("batch_limit"), "50")
})

test_that("batch_limit defaults to 200", {
  withr::local_envvar(batch_limit = NA)
  batch_limit()
  expect_identical(Sys.getenv("batch_limit"), "200")
})

test_that("batch_limit with non-numeric input warns and leaves default", {
  withr::local_envvar(batch_limit = NA)
  # Unset entry is seeded to "200" before the numeric check runs.
  expect_message(batch_limit("lots"), "Invalid limit option")
  expect_identical(Sys.getenv("batch_limit"), "200")
})
