test_that("load_hook_config populates .HookRegistry from YAML", {
  # Clear registry first
  .HookRegistry$config <- NULL

  # Load config
  load_hook_config()

  # Verify registry is populated
  expect_type(.HookRegistry$config, "list")
  expect_true(length(.HookRegistry$config) > 0)

  # Verify known entries exist
  expect_true("ct_lists_all" %in% names(.HookRegistry$config))
  expect_true("ct_similar" %in% names(.HookRegistry$config))
  expect_true("ct_list" %in% names(.HookRegistry$config))
})

test_that("run_hook returns data unchanged when no hooks registered", {
  # Clear registry
  .HookRegistry$config <- list()

  # Call run_hook on non-existent function
  input_data <- list(x = 1, y = "test")
  result <- run_hook("nonexistent_function", "pre_request", input_data)

  # Verify data unchanged
  expect_identical(result, input_data)
})

test_that("run_hook returns data unchanged for unregistered hook type", {
  # Set up registry with ct_lists_all but no pre_request hook
  .HookRegistry$config <- list(
    ct_lists_all = list(
      transform = c("lists_all_transform")
    )
  )

  # Call run_hook with unregistered hook type
  input_data <- list(x = 1, y = "test")
  result <- run_hook("ct_lists_all", "pre_request", input_data)

  # Verify data unchanged
  expect_identical(result, input_data)
})

test_that("run_hook executes single hook function", {
  # Define test hook that adds a marker
  test_hook_single <- function(data) {
    data$marker <- "executed"
    data
  }

  # Register the hook
  .HookRegistry$config <- list(
    test_function = list(
      pre_request = c("test_hook_single")
    )
  )

  # Clean up after test
  withr::defer({
    .HookRegistry$config <- list()
  })

  # Run hook
  input_data <- list(x = 1)
  result <- run_hook("test_function", "pre_request", input_data)

  # Verify marker is present
  expect_true("marker" %in% names(result))
  expect_equal(result$marker, "executed")
})

test_that("run_hook executes hook chain in order", {
  # Define two hooks that append to a log
  test_hook_first <- function(data) {
    data$log <- c(data$log, "first")
    data
  }

  test_hook_second <- function(data) {
    data$log <- c(data$log, "second")
    data
  }

  # Register hook chain
  .HookRegistry$config <- list(
    test_function = list(
      transform = c("test_hook_first", "test_hook_second")
    )
  )

  # Clean up after test
  withr::defer({
    .HookRegistry$config <- list()
  })

  # Run hooks
  input_data <- list(log = character(0))
  result <- run_hook("test_function", "transform", input_data)

  # Verify order
  expect_equal(result$log, c("first", "second"))
})

test_that("run_hook errors informatively on missing hook function", {
  # Register non-existent function
  .HookRegistry$config <- list(
    test_function = list(
      pre_request = c("nonexistent_hook_function")
    )
  )

  # Clean up after test
  withr::defer({
    .HookRegistry$config <- list()
  })

  # Run hook and expect error
  input_data <- list(x = 1)
  expect_error(
    run_hook("test_function", "pre_request", input_data),
    regexp = "nonexistent_hook_function"
  )
})
