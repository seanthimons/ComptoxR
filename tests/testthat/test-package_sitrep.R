# Tests for package_sitrep
# This function generates diagnostic reports

test_that("package_sitrep runs without errors", {
  # Run the function in a temporary directory
  withr::with_tempdir({
    result <- package_sitrep()
    
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
    expect_true("local_fallback" %in% names(result))
    
    # Check that log file was created
    expect_true(file.exists(result$log_file))
    
    # Check that log file contains expected sections
    log_content <- readLines(result$log_file)
    expect_true(any(grepl("PACKAGE VERSION", log_content)))
    expect_true(any(grepl("API TOKENS STATUS", log_content)))
    expect_true(any(grepl("CONFIGURED SERVER PATHS", log_content)))
    expect_true(any(grepl("PING TEST RESULTS", log_content)))
    expect_true(any(grepl("LOCAL FALLBACK IMPLEMENTATION", log_content)))
  })
})

test_that("package_sitrep creates timestamped log file", {
  withr::with_tempdir({
    result <- package_sitrep()
    
    # Check log file naming pattern
    expect_match(result$log_file, "^comptoxr_sitrep_\\d{8}_\\d{6}\\.log$")
  })
})

test_that("package_sitrep detects API token status correctly", {
  withr::with_tempdir({
    # Save original env vars
    orig_ctx <- Sys.getenv("ctx_api_key", unset = NA)
    orig_cc <- Sys.getenv("cc_api_key", unset = NA)
    
    # Test with no tokens set
    Sys.unsetenv("ctx_api_key")
    Sys.unsetenv("cc_api_key")
    
    result <- package_sitrep()
    expect_false(result$api_tokens$ctx_api_key)
    expect_false(result$api_tokens$cc_api_key)
    
    # Test with tokens set
    Sys.setenv(ctx_api_key = "test_token_123")
    Sys.setenv(cc_api_key = "test_cc_token_456")
    
    result <- package_sitrep()
    expect_true(result$api_tokens$ctx_api_key)
    expect_true(result$api_tokens$cc_api_key)
    
    # Restore original env vars
    if (!is.na(orig_ctx)) Sys.setenv(ctx_api_key = orig_ctx) else Sys.unsetenv("ctx_api_key")
    if (!is.na(orig_cc)) Sys.setenv(cc_api_key = orig_cc) else Sys.unsetenv("cc_api_key")
  })
})

test_that("package_sitrep captures server paths", {
  withr::with_tempdir({
    result <- package_sitrep()
    
    # Check that server_paths is a list
    expect_type(result$server_paths, "list")
    
    # Check that expected servers are present
    expect_true("CompTox Dashboard API" %in% names(result$server_paths))
    expect_true("Cheminformatics API" %in% names(result$server_paths))
    expect_true("Common Chemistry API" %in% names(result$server_paths))
  })
})

test_that("package_sitrep returns ping results", {
  withr::with_tempdir({
    result <- package_sitrep()
    
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
