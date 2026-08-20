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

run_debug_enabled <- getFromNamespace(".run_debug_enabled", "ComptoxR")
run_verbose_enabled <- getFromNamespace(".run_verbose_enabled", "ComptoxR")
on_attach <- getFromNamespace(".onAttach", "ComptoxR")

test_that("run_debug changes private session state", {
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)

  expect_invisible(suppressMessages(run_debug(TRUE)))
  expect_true(run_debug_enabled())

  expect_invisible(suppressMessages(run_debug(FALSE)))
  expect_false(run_debug_enabled())
})

test_that("missing settings default to FALSE", {
  withr::local_options(list(ComptoxR.run_verbose = NULL))
  state <- getFromNamespace(".ComptoxREnv", "ComptoxR")
  old_debug <- state$run_debug
  on.exit(assign("run_debug", old_debug, envir = state), add = TRUE)
  rm("run_debug", envir = state)

  expect_false(run_debug_enabled())
  expect_false(run_verbose_enabled())
})

test_that("invalid debug values warn and reset private state", {
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)

  for (value in list(42, NA, c(TRUE, FALSE))) {
    suppressMessages(run_debug(TRUE))
    expect_message(run_debug(value), "Invalid debug option")
    expect_false(run_debug_enabled())
  }
})

# ---- run_verbose -----------------------------------------------------------

test_that("run_verbose changes the namespaced option", {
  withr::local_options(list(ComptoxR.run_verbose = NULL))

  expect_invisible(suppressMessages(run_verbose(TRUE)))
  expect_identical(getOption("ComptoxR.run_verbose"), TRUE)

  expect_invisible(suppressMessages(run_verbose(FALSE)))
  expect_identical(getOption("ComptoxR.run_verbose"), FALSE)
})

test_that("invalid verbose values warn and reset the option", {
  withr::local_options(list(ComptoxR.run_verbose = NULL))

  for (value in list(42, NA, c(TRUE, FALSE))) {
    suppressMessages(run_verbose(TRUE))
    expect_message(run_verbose(value), "Invalid verbose option")
    expect_identical(getOption("ComptoxR.run_verbose"), FALSE)
  }
})

test_that("legacy environment variables do not control runtime settings", {
  withr::local_envvar(c(run_debug = "TRUE", run_verbose = "TRUE"))
  withr::local_options(list(ComptoxR.run_verbose = NULL))
  state <- getFromNamespace(".ComptoxREnv", "ComptoxR")
  old_debug <- state$run_debug
  on.exit(assign("run_debug", old_debug, envir = state), add = TRUE)
  state$run_debug <- FALSE

  expect_false(run_debug_enabled())
  expect_false(run_verbose_enabled())
})

test_that("setters leave legacy environment variables unchanged", {
  withr::local_envvar(c(
    run_debug = "legacy-debug",
    run_verbose = "legacy-verbose"
  ))
  withr::local_options(list(ComptoxR.run_verbose = NULL))
  on.exit(suppressMessages(run_debug(FALSE)), add = TRUE)

  suppressMessages(run_debug(TRUE))
  suppressMessages(run_verbose(TRUE))

  expect_identical(Sys.getenv("run_debug"), "legacy-debug")
  expect_identical(Sys.getenv("run_verbose"), "legacy-verbose")
})

test_that("package attachment uses a verbose option set before attachment", {
  withr::local_options(list(ComptoxR.run_verbose = TRUE))
  withr::local_envvar(R_DEVTOOLS_LOAD = "")
  header_called <- FALSE
  testthat::local_mocked_bindings(
    .header = function() {
      header_called <<- TRUE
    },
    .package = "ComptoxR"
  )

  suppressPackageStartupMessages(on_attach("", "ComptoxR"))

  expect_true(header_called)
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
