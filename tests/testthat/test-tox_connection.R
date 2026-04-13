# Tests for ToxValDB connection infrastructure
# -------------------------------------------------------------------

# Always-run tests (no database required) --------------------------------

test_that("toxval_path()() returns path ending in toxval.duckdb", {
  path <- toxval_path()()
  expect_true(grepl("toxval\\.duckdb$", path))
})

test_that("toxval_path()() respects options(ComptoxR.toxval_path)", {
  withr::with_options(
    list(ComptoxR.toxval_path = "/tmp/custom_toxval.duckdb"),
    {
      expect_equal(toxval_path()(), "/tmp/custom_toxval.duckdb")
    }
  )
})

test_that(".tox_get_con() aborts when DB missing", {
  withr::with_options(
    list(ComptoxR.toxval_path = "/nonexistent/path/toxval.duckdb"),
    {
      withr::with_envvar(c("toxval_burl()" = ""), {
        expect_error(.tox_get_con(), "ToxValDB database not found")
      })
    }
  )
})

test_that(".tox_close_con() is safe with no connection", {
  # Should not error even when there's nothing to close
  old <- .ComptoxREnv$toxval_db
  .ComptoxREnv$toxval_db <- NULL
  expect_silent(.tox_close_con())
  .ComptoxREnv$toxval_db <- old
})

test_that("toxval_server()(NULL) resets toxval_burl()", {
  old <- Sys.getenv("toxval_burl()")
  suppressMessages(toxval_server()(NULL))
  expect_equal(Sys.getenv("toxval_burl()"), "")
  # Restore
  Sys.setenv("toxval_burl()" = old)
})

test_that("toxval_server()(99) warns invalid option", {
  old <- Sys.getenv("toxval_burl()")
  expect_message(toxval_server()(99), "Invalid server option")
  # Restore
  Sys.setenv("toxval_burl()" = old)
})

test_that("toxval_server()() with nonexistent file path aborts", {
  expect_error(toxval_server()("/nonexistent.duckdb"), "not found")
})


# Download helper tests ---------------------------------------------------

test_that(".db_download_release() aborts on 404 / missing asset", {
  # Mock httr2::req_perform to simulate a GitHub API error
  local_mocked_bindings(
    req_perform = function(...) {
      cli::cli_abort("HTTP 404: Not Found")
    },
    .package = "httr2"
  )

  expect_error(
    .db_download_release("toxval", tempfile()),
    "Failed to fetch release info"
  )
})

test_that("tox_install() default path calls .db_download_release", {
  download_called <- FALSE

  local_mocked_bindings(
    .db_download_release = function(db_name, dest_path, tag, ...) {
      download_called <<- TRUE
      expect_equal(db_name, "toxval")
      expect_equal(tag, "latest")
      # Simulate successful download by writing a tiny file
      writeBin(raw(0), dest_path)
    }
  )

  dest <- withr::local_tempdir()
  withr::local_options(ComptoxR.toxval_path = file.path(dest, "toxval.duckdb"))

  tox_install(overwrite = TRUE)
  expect_true(download_called)
})

test_that("tox_install(build = TRUE) skips download", {
  download_called <- FALSE

  local_mocked_bindings(
    .db_download_release = function(...) {
      download_called <<- TRUE
    },
    .tox_build_from_source = function(dest) {
      writeBin(raw(0), dest)
    }
  )

  dest <- withr::local_tempdir()
  withr::local_options(ComptoxR.toxval_path = file.path(dest, "toxval.duckdb"))

  tox_install(build = TRUE, overwrite = TRUE)
  expect_false(download_called)
})

test_that("tox_install() falls back to build on download failure", {
  build_called <- FALSE

  local_mocked_bindings(
    .db_download_release = function(...) {
      cli::cli_abort("No assets found")
    },
    .tox_build_from_source = function(dest) {
      build_called <<- TRUE
      writeBin(raw(0), dest)
    }
  )

  dest <- withr::local_tempdir()
  withr::local_options(ComptoxR.toxval_path = file.path(dest, "toxval.duckdb"))

  expect_warning(
    tox_install(overwrite = TRUE),
    "Could not download"
  )
  expect_true(build_called)
})

# Build pipeline tests ---------------------------------------------------

# Helper: load .build_toxval_db() without triggering the trailing auto-invoke.
# Parses the build script and evaluates only the function/constant definitions.
.load_build_defs <- function(env = parent.frame()) {
  build_script <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
  if (!nzchar(build_script)) return(invisible(FALSE))
  exprs <- parse(build_script)
  # Evaluate everything except the bare .build_toxval_db() call at the end
  for (expr in exprs) {
    txt <- deparse(expr, width.cutoff = 500L)
    if (identical(trimws(paste(txt, collapse = "")), ".build_toxval_db()")) next
    eval(expr, envir = env)
  }
  invisible(TRUE)
}

test_that("build script self-invokes when sourced into isolated env", {
  build_script <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
  skip_if(!nzchar(build_script), "Build script not found (not dev install)")

  # Source into an isolated env — the real invocation path used by
  # .tox_build_from_source(). Verify the function actually executes
  # (not just gets defined and discarded). We detect execution by
  # checking that cli messages were emitted (staleness check or Clowder query).
  msgs <- character(0)
  result <- withCallingHandlers(
    tryCatch(
      source(build_script, local = new.env(parent = globalenv())),
      error = function(e) conditionMessage(e)
    ),
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )

  # If the function ran, it would emit at least one cli message
  # (staleness skip, Clowder query, or dependency check)
  ran <- length(msgs) > 0 || (is.character(result) && nzchar(result))
  expect_true(ran, label = "build script should execute .build_toxval_db() on source")
})

test_that(".build_toxval_db staleness check skips fresh database", {
  build_script <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
  skip_if(!nzchar(build_script), "Build script not found (not dev install)")
  .load_build_defs()

  # Create a fake "fresh" database file
  tmp <- withr::local_tempdir()
  db_path <- file.path(tmp, "toxval.duckdb")
  writeBin(raw(10), db_path)

  # Touch it so mtime is now (< 180 days)
  Sys.setFileTime(db_path, Sys.time())

  # Should return early without calling Clowder
  result <- .build_toxval_db(output_path = db_path, force = FALSE)
  expect_equal(result, db_path)
  # File should still be the original 10-byte stub (not rebuilt)
  expect_equal(file.size(db_path), 10)
})

test_that(".build_toxval_db force=TRUE bypasses staleness", {
  build_script <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
  skip_if(!nzchar(build_script), "Build script not found (not dev install)")
  .load_build_defs()

  # Create a fresh database file (normally would be skipped by staleness check)
  tmp <- withr::local_tempdir()
  db_path <- file.path(tmp, "toxval.duckdb")
  writeBin(raw(10), db_path)

  # force=TRUE should NOT short-circuit. The build will either succeed
  # (changing the file) or fail at Clowder/network. Either way, verify
  # it attempted the build by checking the file was modified or an error
  # related to the build (not staleness) was thrown.
  result <- tryCatch(
    {
      .build_toxval_db(output_path = db_path, force = TRUE)
      "success"
    },
    error = function(e) conditionMessage(e)
  )

  if (result == "success") {
    # Build succeeded — file should be larger than 10 bytes
    expect_true(file.size(db_path) > 10)
  } else {
    # Build failed at network/Clowder — that's fine, it didn't short-circuit
    expect_false(grepl("up-to-date", result, ignore.case = TRUE))
  }
})

test_that("version extraction handles standard v97_0 format", {
  # Test the regex used in .build_toxval_db
  version_raw <- stringr::str_extract("toxval_v97_0_src_iris.xlsx", "v\\d{2,3}_\\d+")
  expect_equal(version_raw, "v97_0")

  # Test label derivation
  parts <- regmatches(version_raw, regexec("v(\\d+)_(\\d+)", version_raw))[[1]]
  expect_length(parts, 3)
  major_raw <- as.integer(parts[2])
  minor <- as.integer(parts[3])
  label <- sprintf("%d.%d.%d", major_raw %/% 10, major_raw %% 10, minor)
  expect_equal(label, "9.7.0")
})

test_that("version extraction handles v100_1 format", {
  version_raw <- stringr::str_extract("toxval_v100_1_src.xlsx", "v\\d{2,3}_\\d+")
  expect_equal(version_raw, "v100_1")

  parts <- regmatches(version_raw, regexec("v(\\d+)_(\\d+)", version_raw))[[1]]
  major_raw <- as.integer(parts[2])
  minor <- as.integer(parts[3])
  label <- sprintf("%d.%d.%d", major_raw %/% 10, major_raw %% 10, minor)
  expect_equal(label, "10.0.1")
})

test_that("version extraction fallback on unrecognized filename", {
  version_raw <- stringr::str_extract("some_random_file.xlsx", "v\\d{2,3}_\\d+")
  expect_true(is.na(version_raw))
})

test_that("atomic build produces valid DuckDB on success", {
  # Verify the in-memory → persist pattern works
  tmp <- withr::local_tempdir()
  db_path <- file.path(tmp, "test_atomic.duckdb")

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  DBI::dbWriteTable(con, "test_tbl", data.frame(x = 1:5, y = letters[1:5]))

  safe_path <- gsub("\\\\", "/", db_path)
  DBI::dbExecute(con, sprintf("ATTACH '%s' AS persist", safe_path))
  DBI::dbExecute(con, "COPY FROM DATABASE memory TO persist")
  DBI::dbExecute(con, "DETACH persist")

  # Verify the persisted DB is readable
  expect_true(file.exists(db_path))
  verify_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(verify_con, shutdown = TRUE), add = TRUE)

  result <- DBI::dbGetQuery(verify_con, "SELECT count(*) AS n FROM test_tbl")
  expect_equal(result$n, 5L)
})

test_that("row count threshold constant is reasonable", {
  build_script <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
  skip_if(!nzchar(build_script), "Build script not found (not dev install)")
  .load_build_defs()

  # Verify the constant exists and is a sensible value
  expect_true(exists(".TOXVAL_MIN_ROWS"))
  expect_true(.TOXVAL_MIN_ROWS >= 50000L)
  expect_true(.TOXVAL_MIN_ROWS <= 500000L)
})

# Live tests (database required) ------------------------------------------

test_that("connection returns valid DBIConnection", {
  skip_if_not(file.exists(toxval_path()()), "ToxValDB not installed")

  con <- .tox_get_con()
  expect_true(inherits(con, "DBIConnection"))
  expect_true(DBI::dbIsValid(con))
})

test_that(".tox_get_con() returns same cached connection", {
  skip_if_not(file.exists(toxval_path()()), "ToxValDB not installed")

  con1 <- .tox_get_con()
  con2 <- .tox_get_con()
  expect_identical(con1, con2)
})

test_that("tox_health() returns expected fields", {
  skip_if_not(file.exists(toxval_path()()), "ToxValDB not installed")

  health <- tox_health()
  expect_type(health, "list")
  expect_true("status" %in% names(health))
  expect_true("db_path" %in% names(health))
  expect_true("version_label" %in% names(health))
  expect_true("db_size_mb" %in% names(health))
})
