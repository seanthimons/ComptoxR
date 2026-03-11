# Load hook functions (they're not exported, so we need to source them)
# Hook files are in R/hooks/ and contain @noRd functions
hook_files <- list.files(here::here("R/hooks"), pattern = "\\.R$", full.names = TRUE)
for (hook_file in hook_files) {
  source(hook_file)
}

test_that("coerce_by_property_id returns result unchanged when coerce=FALSE", {
  # Mock data structure
  mock_data <- list(
    result = tibble::tibble(
      dtxsid = c("DTXSID001", "DTXSID002", "DTXSID003"),
      propertyId = c("MolWeight", "MolWeight", "LogP"),
      value = c(100, 150, 2.5)
    ),
    params = list(coerce = FALSE)
  )

  result <- coerce_by_property_id(mock_data)

  # Should return original tibble unchanged
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 3)
})

test_that("coerce_by_property_id splits by propertyId when coerce=TRUE", {
  # Mock data with multiple propertyId values
  mock_data <- list(
    result = tibble::tibble(
      dtxsid = c("DTXSID001", "DTXSID002", "DTXSID003", "DTXSID004"),
      propertyId = c("MolWeight", "MolWeight", "LogP", "LogP"),
      value = c(100, 150, 2.5, 3.2)
    ),
    params = list(coerce = TRUE)
  )

  result <- coerce_by_property_id(mock_data)

  # Should return named list split by propertyId
  expect_type(result, "list")
  expect_named(result, c("LogP", "MolWeight"))
  expect_equal(length(result), 2)

  # Verify each group
  expect_s3_class(result$MolWeight, "tbl_df")
  expect_equal(nrow(result$MolWeight), 2)

  expect_s3_class(result$LogP, "tbl_df")
  expect_equal(nrow(result$LogP), 2)
})

test_that("coerce_by_property_id handles empty tibble gracefully", {
  # Mock data with empty result
  mock_data <- list(
    result = tibble::tibble(
      dtxsid = character(),
      propertyId = character(),
      value = numeric()
    ),
    params = list(coerce = TRUE)
  )

  result <- coerce_by_property_id(mock_data)

  # Should return empty tibble (no split possible)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("coerce_by_property_id works with single propertyId when coerce=TRUE", {
  # Mock data with only one propertyId
  mock_data <- list(
    result = tibble::tibble(
      dtxsid = c("DTXSID001", "DTXSID002"),
      propertyId = c("MolWeight", "MolWeight"),
      value = c(100, 150)
    ),
    params = list(coerce = TRUE)
  )

  result <- coerce_by_property_id(mock_data)

  # Should return named list with single group
  expect_type(result, "list")
  expect_named(result, "MolWeight")
  expect_equal(length(result), 1)
  expect_s3_class(result$MolWeight, "tbl_df")
  expect_equal(nrow(result$MolWeight), 2)
})
