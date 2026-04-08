# Tests for eco_functions.R
# ----------------------------------------------------------

# Always-run tests (no database needed) -----------------------------------

test_that("eco_results() aborts when no filter params given", {
  expect_error(eco_results(), "At least one filter")
})

test_that("eco_results() aborts with public URL eco_burl", {
  withr::with_envvar(c(eco_burl = "https://cfpub.epa.gov/ecotox/index.cfm"), {
    expect_error(eco_results(casrn = "50-29-3"), "no public REST API")
  })
})

test_that("eco_fields() rejects non-character input", {
  withr::with_envvar(c(eco_burl = "https://cfpub.epa.gov/ecotox/index.cfm"), {
    expect_error(eco_fields(123), "character")
  })
})

test_that("eco_species() rejects invalid field argument", {
  withr::with_envvar(c(eco_burl = "https://cfpub.epa.gov/ecotox/index.cfm"), {
    expect_error(eco_species("x", field = "bad"), "should be one of")
  })
})


# Live tests (require local ECOTOX database) ------------------------------

# All guarded by skip_if_not — will not fail in CI/CRAN without DB
db_available <- file.exists(eco_path())

test_that("eco_results() returns enriched tibble for DDT", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_results(casrn = "50-29-3")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true(all(c("test_cas", "endpoint", "final_conc") %in% names(result)))
})

test_that("eco_results() filters by common_name", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_results(common_name = "Rainbow Trout")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true(all(
    grepl("Rainbow Trout", result$common_name, ignore.case = TRUE)
  ))
})

test_that("eco_results() default endpoints match curated regex", {

  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_results(casrn = "50-29-3", endpoint = "default")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)

  default_regex <- paste0(
    "^EC50|^LC50|^LD50|LR50|^LOEC|^LOEL|NOEC|NOEL$|",
    "NR-ZERO|NR-LETH|AC50|\\(log\\)EC50|\\(log\\)LC50|\\(log\\)LOEC"
  )
  expect_true(all(grepl(default_regex, result$endpoint)))
})

test_that("eco_results() custom endpoint LC50", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_results(casrn = "50-29-3", endpoint = "LC50")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true(all(grepl("LC50", result$endpoint)))
})

test_that("eco_inventory() returns chemicals tibble", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_inventory()
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("cas_number", "chemical_name", "dtxsid") %in% names(result)))
})

test_that("eco_tables() returns character vector with core tables", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_tables()
  expect_type(result, "character")
  expect_true(all(c("tests", "results", "species") %in% result))
})

test_that("eco_fields() returns column names for tests table", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_fields("tests")
  expect_type(result, "character")
  expect_true(all(c("test_id", "test_cas", "species_number") %in% result))
})

test_that("eco_species() finds Rainbow trout", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_species("Rainbow%")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true(all(c("common_name", "eco_group") %in% names(result)))
})

test_that("eco_health() returns status list", {
  skip_if_not(db_available, "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  suppressMessages(eco_server(4))
  on.exit(Sys.setenv(eco_burl = old_burl), add = TRUE)

  result <- eco_health()
  expect_type(result, "list")
  expect_equal(result$status, "ok")
  expect_gt(result$db_size_mb, 0)
})
