test_that("run_quiet sets options correctly", {
  # Save original state
  orig_option <- getOption("ComptoxR.quiet")
  orig_env <- Sys.getenv("COMPTOXR_STARTUP_QUIET")
  
  # Test setting quiet mode to TRUE
  run_quiet(TRUE)
  expect_true(getOption("ComptoxR.quiet"))
  expect_equal(Sys.getenv("COMPTOXR_STARTUP_QUIET"), "TRUE")
  
  # Test setting quiet mode to FALSE
  run_quiet(FALSE)
  expect_false(getOption("ComptoxR.quiet"))
  expect_equal(Sys.getenv("COMPTOXR_STARTUP_QUIET"), "FALSE")
  
  # Restore original state
  if (is.null(orig_option)) {
    options(ComptoxR.quiet = NULL)
  } else {
    options(ComptoxR.quiet = orig_option)
  }
  Sys.setenv(COMPTOXR_STARTUP_QUIET = orig_env)
})

test_that("run_quiet handles invalid input", {
  # Save original state
  orig_option <- getOption("ComptoxR.quiet")
  orig_env <- Sys.getenv("COMPTOXR_STARTUP_QUIET")
  
  # Test with invalid input
  expect_message(run_quiet("invalid"), "Invalid quiet option")
  expect_false(getOption("ComptoxR.quiet"))
  expect_equal(Sys.getenv("COMPTOXR_STARTUP_QUIET"), "FALSE")
  
  # Restore original state
  if (is.null(orig_option)) {
    options(ComptoxR.quiet = NULL)
  } else {
    options(ComptoxR.quiet = orig_option)
  }
  Sys.setenv(COMPTOXR_STARTUP_QUIET = orig_env)
})

test_that(".should_suppress_startup detects quiet option", {
  # Save original state
  orig_option <- getOption("ComptoxR.quiet")
  orig_env <- Sys.getenv("COMPTOXR_STARTUP_QUIET")
  
  # Test with option set to TRUE
  options(ComptoxR.quiet = TRUE)
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = "false")
  expect_true(ComptoxR:::.should_suppress_startup())
  
  # Test with env var set to true
  options(ComptoxR.quiet = FALSE)
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = "true")
  expect_true(ComptoxR:::.should_suppress_startup())
  
  # Test with both FALSE
  options(ComptoxR.quiet = FALSE)
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = "false")
  expect_false(ComptoxR:::.should_suppress_startup())
  
  # Test with both TRUE
  options(ComptoxR.quiet = TRUE)
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = "true")
  expect_true(ComptoxR:::.should_suppress_startup())
  
  # Restore original state
  if (is.null(orig_option)) {
    options(ComptoxR.quiet = NULL)
  } else {
    options(ComptoxR.quiet = orig_option)
  }
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = orig_env)
})

test_that("run_setup respects quiet mode", {
  # Save original state
  orig_option <- getOption("ComptoxR.quiet")
  orig_env <- Sys.getenv("COMPTOXR_STARTUP_QUIET")
  
  # Set quiet mode
  options(ComptoxR.quiet = TRUE)
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = "true")
  
  # run_setup should return invisible NULL without any output
  result <- run_setup()
  expect_null(result)
  
  # Restore original state
  if (is.null(orig_option)) {
    options(ComptoxR.quiet = NULL)
  } else {
    options(ComptoxR.quiet = orig_option)
  }
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = orig_env)
})

test_that("run_verbose respects quiet mode when called during startup", {
  # Save original state
  orig_option <- getOption("ComptoxR.quiet")
  orig_env_quiet <- Sys.getenv("COMPTOXR_STARTUP_QUIET")
  orig_env_verbose <- Sys.getenv("run_verbose")
  
  # Set quiet mode
  options(ComptoxR.quiet = TRUE)
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = "true")
  
  # run_verbose should not output messages when quiet mode is on
  # It should still set the environment variable
  expect_silent(run_verbose(TRUE))
  expect_equal(Sys.getenv("run_verbose"), "TRUE")
  
  expect_silent(run_verbose(FALSE))
  expect_equal(Sys.getenv("run_verbose"), "FALSE")
  
  # Restore original state
  if (is.null(orig_option)) {
    options(ComptoxR.quiet = NULL)
  } else {
    options(ComptoxR.quiet = orig_option)
  }
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = orig_env_quiet)
  Sys.setenv("run_verbose" = orig_env_verbose)
})

test_that("run_debug respects quiet mode when called during startup", {
  # Save original state
  orig_option <- getOption("ComptoxR.quiet")
  orig_env_quiet <- Sys.getenv("COMPTOXR_STARTUP_QUIET")
  orig_env_debug <- Sys.getenv("run_debug")
  
  # Set quiet mode
  options(ComptoxR.quiet = TRUE)
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = "true")
  
  # run_debug should not output messages when quiet mode is on
  # It should still set the environment variable
  expect_silent(run_debug(TRUE))
  expect_equal(Sys.getenv("run_debug"), "TRUE")
  
  expect_silent(run_debug(FALSE))
  expect_equal(Sys.getenv("run_debug"), "FALSE")
  
  # Restore original state
  if (is.null(orig_option)) {
    options(ComptoxR.quiet = NULL)
  } else {
    options(ComptoxR.quiet = orig_option)
  }
  Sys.setenv("COMPTOXR_STARTUP_QUIET" = orig_env_quiet)
  Sys.setenv("run_debug" = orig_env_debug)
})
