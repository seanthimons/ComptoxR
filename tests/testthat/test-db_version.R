test_that(".db_rebuild_needed handles the publish gate truth table", {
  expect_true(.db_rebuild_needed("a", "a", asset_age_days = 1, force = TRUE, backstop_days = 10)$needed)
  expect_true(.db_rebuild_needed("", "a", asset_age_days = 1, force = FALSE, backstop_days = 10)$needed)
  expect_true(.db_rebuild_needed("a", "b", asset_age_days = 1, force = FALSE, backstop_days = 10)$needed)
  expect_false(.db_rebuild_needed("a", "a", asset_age_days = 1, force = FALSE, backstop_days = 10)$needed)

  over_backstop <- .db_rebuild_needed("a", "a", asset_age_days = 11, force = FALSE, backstop_days = 10)
  expect_true(over_backstop$needed)
  expect_equal(over_backstop$reason, "backstop_age")
})

test_that("upstream version probes return non-empty strings", {
  skip_if_offline()

  expect_match(.dsstox_latest_upstream_version(), ".+\\|.+")
  expect_match(.ecotox_latest_upstream_version(), "^ecotox_ascii_[0-9]{2}_[0-9]{2}_[0-9]{4}[.]zip$")
  expect_match(.toxval_latest_upstream_version(), "^v[0-9]{2,3}_[0-9]+$")
})

test_that(".db_gate_decision emits parseable outputs", {
  testthat::local_mocked_bindings(
    .db_latest_upstream_version = function(db_name) {
      expect_equal(db_name, "toxval")
      "v99_0"
    },
    .package = "ComptoxR"
  )

  output_path <- tempfile()
  withr::local_envvar(GITHUB_OUTPUT = output_path)

  decision <- .db_gate_decision(
    db_name = "toxval",
    published_version = "v98_0",
    asset_age_days = 1,
    force = FALSE,
    backstop_days = 30
  )
  output <- readLines(output_path, warn = FALSE)

  expect_true(decision$needed)
  expect_true(any(output == "needed=true"))
  expect_true(any(output == "upstream_version=v99_0"))
})

test_that("freshness diagnostics report stale DSSTox metadata", {
  path <- file.path(withr::local_tempdir(), "dsstox.duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = FALSE)
  DBI::dbWriteTable(
    con,
    "_metadata",
    data.frame(
      key = c("dsstox_release_date", "dsstox_clowder_id"),
      value = c("old-date", "old-id")
    )
  )
  DBI::dbDisconnect(con, shutdown = TRUE)

  testthat::local_mocked_bindings(
    .dsstox_latest_upstream_version = function() "new-date|new-id",
    .package = "ComptoxR"
  )

  result <- dss_diag_freshness(path = path)
  expect_equal(result$status, "stale")
  expect_equal(result$local_version, "old-date|old-id")
  expect_equal(result$latest_upstream_version, "new-date|new-id")
})

test_that("freshness diagnostics report stale ECOTOX metadata", {
  path <- file.path(withr::local_tempdir(), "ecotox.duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = FALSE)
  DBI::dbWriteTable(
    con,
    "_metadata",
    data.frame(
      key = "ecotox_release",
      value = "ecotox_ascii_01_01_2024.zip"
    )
  )
  DBI::dbDisconnect(con, shutdown = TRUE)

  testthat::local_mocked_bindings(
    .ecotox_latest_upstream_version = function() "ecotox_ascii_06_11_2026.zip",
    .package = "ComptoxR"
  )

  result <- eco_diag_freshness(path = path)
  expect_equal(result$status, "stale")
  expect_equal(result$local_version, "ecotox_ascii_01_01_2024.zip")
  expect_equal(result$latest_upstream_version, "ecotox_ascii_06_11_2026.zip")
})

test_that("install defaults request the rolling db-latest release", {
  testthat::local_mocked_bindings(
    .db_download_release = function(db_name, dest_path, tag, ...) {
      expect_equal(db_name, "dsstox")
      expect_equal(tag, "db-latest")
      writeBin(raw(0), dest_path)
    },
    .package = "ComptoxR"
  )

  dest <- file.path(withr::local_tempdir(), "dsstox.duckdb")
  withr::local_options(ComptoxR.dsstox_path = dest)
  expect_equal(dss_install(overwrite = TRUE), dest)
})
