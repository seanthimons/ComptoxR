# Tests for DSSTox local database functions
# ==========================================

# -- Always-run tests (no database needed) ----------------------------------

test_that("dss_path() returns correct default path", {
  withr::with_options(list(ComptoxR.dsstox_path = NULL), {
    path <- dss_path()
    expect_true(grepl("ComptoxR", path))
    expect_true(grepl("dsstox\\.duckdb$", path))
  })
})

test_that("dss_path() respects ComptoxR.dsstox_path option", {
  withr::with_options(list(ComptoxR.dsstox_path = "/tmp/custom.duckdb"), {
    expect_equal(dss_path(), "/tmp/custom.duckdb")
  })
})

test_that("dss_get_con() aborts with helpful message when DB missing", {
  withr::with_options(list(ComptoxR.dsstox_path = "/nonexistent/path/nope.duckdb"), {
    # Clear cached connection
    old_con <- .ComptoxREnv$dsstox_db
    .ComptoxREnv$dsstox_db <- NULL
    on.exit(.ComptoxREnv$dsstox_db <- old_con, add = TRUE)

    expect_error(dss_get_con(), "not found")
  })
})

test_that("dss_search() rejects invalid cols values", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  expect_error(dss_search("test%", cols = "EVIL_COL"), "Invalid column")
  expect_error(dss_search("test%", cols = c("CASRN", "DROP_TABLE")), "Invalid column")
})

test_that("dss_fuzzy() rejects invalid cols values", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  expect_error(dss_fuzzy("test", cols = "EVIL_COL"), "Invalid column")
})

test_that("dss_fuzzy() validates query type", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  expect_error(dss_fuzzy(""), "non-empty")
  expect_error(dss_fuzzy(123), "non-empty")
  expect_error(dss_fuzzy(c("a", "b")), "non-empty")
})

# -- Live tests (require database) ------------------------------------------

test_that("dss_query() returns results for known chemical", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_query("Formaldehyde")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true("DTXSID" %in% names(result))
})

test_that("dss_synonyms() returns tibble with expected columns", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_synonyms("DTXSID7020637")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true(all(c("DTXSID", "parent_col", "values") %in% names(result)))
})

test_that("dss_synonyms() handles vector input", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_synonyms(c("DTXSID7020637", "DTXSID7020182"))
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  # Should have results for both DTXSIDs
  expect_true(all(c("DTXSID7020637", "DTXSID7020182") %in% result$DTXSID))
})

test_that("dss_resolve() returns DTXSID and PREFERRED_NAME", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_resolve(c("50-00-0", "DTXSID7020637"))
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("input", "DTXSID", "PREFERRED_NAME", "CASRN") %in% names(result)))
  expect_gt(nrow(result), 0)
})

test_that("dss_cas() returns DTXSID for CAS number", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_cas("50-00-0")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true("DTXSID" %in% names(result))
})

test_that("dss_search() returns limited results", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_search("Benz%", limit = 10)
  expect_s3_class(result, "tbl_df")
  expect_lte(nrow(result), 10)
  expect_gt(nrow(result), 0)
})

test_that("dss_fuzzy() returns similarity scores in [0,1]", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_fuzzy("Atrazine")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true("similarity" %in% names(result))
  expect_true(all(result$similarity >= 0 & result$similarity <= 1))
})

test_that("dss_connect() / dss_disconnect() lifecycle works", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")

  # Disconnect any existing connection first
  old_con <- .ComptoxREnv$dsstox_db
  .ComptoxREnv$dsstox_db <- NULL

  con <- dss_connect()
  expect_true(DBI::dbIsValid(con))

  dss_disconnect()
  expect_null(.ComptoxREnv$dsstox_db)

  # Restore
  .ComptoxREnv$dsstox_db <- old_con
})

# -- dss_resolve() options (fixture connection, no installed database) -------

local_dss_fixture <- function(envir = parent.frame()) {
  testthat::skip_if_not_installed("duckdb")
  substance <- function(id, name, cas, formula, inchikey, iupac, smiles, synonyms) {
    data.frame(
      DTXSID = id,
      parent_col = c(
        "PREFERRED_NAME",
        "CASRN",
        "MOLECULAR_FORMULA",
        "INCHIKEY",
        "IUPAC_NAME",
        "SMILES",
        rep("ident_upper", length(synonyms)),
        rep("IDENTIFIER", length(synonyms))
      ),
      values = c(name, cas, formula, inchikey, iupac, smiles, toupper(synonyms), synonyms),
      sort_order = c(1:6, rep(7L, length(synonyms)), rep(8L, length(synonyms)))
    )
  }
  dsstox <- rbind(
    substance("DTXSID1", "Formaldehyde", "50-00-0", "CH2O", "WSFSSNUMVMOOMR-UHFFFAOYSA-N", "Methanal", "C=O", c("Formalin", "BFV")),
    substance("DTXSID2", "Carbon monoxide", "630-08-0", "CO", "UGFAIRIUMAVXCW-UHFFFAOYSA-N", "Carbon monooxide", "[C-]#[O+]", "Carbon oxide"),
    substance("DTXSID3", "Cobalt", "7440-48-4", "Co", "GUTLYIVDDKVIGB-UHFFFAOYSA-N", "Cobalt", "[Co]", "Co"),
    substance("DTXSID4", "Methanol", "67-56-1", "CH4O", "OKKJLVBELUTLKV-UHFFFAOYSA-N", "Methanol", "CO", "Carbinol")
  )
  con <- DBI::dbConnect(duckdb::duckdb())
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE), envir = envir)
  DBI::dbWriteTable(con, "dsstox", unique(dsstox))
  con
}

# One "input > DTXSID > matched_on" string per row, sorted
dss_resolve_rows <- function(x) {
  sort(paste(x$input, x$DTXSID, x$matched_on, sep = " > "))
}

test_that("dss_resolve() default is exact and case-sensitive on every field", {
  con <- local_dss_fixture()
  result <- dss_resolve(
    c("Formaldehyde", "formaldehyde", "FORMALIN", "BFV", "CO", "DTXSID1", "nope"),
    con = con
  )
  expect_named(result, c("input", "DTXSID", "PREFERRED_NAME", "CASRN", "matched_on"))
  expect_equal(
    dss_resolve_rows(result),
    sort(c(
      "Formaldehyde > DTXSID1 > PREFERRED_NAME",
      "formaldehyde > NA > NA",
      "FORMALIN > DTXSID1 > ident_upper",
      "BFV > DTXSID1 > IDENTIFIER",
      "BFV > DTXSID1 > ident_upper",
      "CO > DTXSID2 > MOLECULAR_FORMULA",
      "CO > DTXSID3 > ident_upper",
      "CO > DTXSID4 > SMILES",
      "DTXSID1 > DTXSID1 > DTXSID",
      "nope > NA > NA"
    ))
  )
  expect_equal(unique(result$PREFERRED_NAME[result$input == "BFV"]), "Formaldehyde")
  expect_equal(unique(result$CASRN[result$input == "BFV"]), "50-00-0")
})

test_that("dss_resolve(ignore_case = TRUE) folds names only", {
  con <- local_dss_fixture()
  result <- dss_resolve(
    c("formaldehyde", "METHANAL", "formalin", "BFV", "co", "CO", "dtxsid1", "ch2o", "wsfssnumvmoomr-uhfffaoysa-n"),
    con = con,
    ignore_case = TRUE
  )
  expect_named(result, c("input", "DTXSID", "PREFERRED_NAME", "CASRN", "matched_on"))
  expect_equal(
    dss_resolve_rows(result),
    sort(c(
      "formaldehyde > DTXSID1 > PREFERRED_NAME",
      "METHANAL > DTXSID1 > IUPAC_NAME",
      "formalin > DTXSID1 > IDENTIFIER",
      "BFV > DTXSID1 > IDENTIFIER",
      "co > DTXSID3 > IDENTIFIER",
      "CO > DTXSID2 > MOLECULAR_FORMULA",
      "CO > DTXSID3 > IDENTIFIER",
      "CO > DTXSID4 > SMILES",
      "dtxsid1 > NA > NA",
      "ch2o > NA > NA",
      "wsfssnumvmoomr-uhfffaoysa-n > NA > NA"
    ))
  )
})

test_that("dss_resolve(fields = ) limits which fields may match", {
  con <- local_dss_fixture()
  name_fields <- c("PREFERRED_NAME", "IUPAC_NAME", "IDENTIFIER", "CASRN")

  expect_equal(
    dss_resolve_rows(dss_resolve(c("CO", "DTXSID1", "50-00-0", "Formalin"), con = con, fields = name_fields)),
    sort(c("CO > NA > NA", "DTXSID1 > NA > NA", "50-00-0 > DTXSID1 > CASRN", "Formalin > DTXSID1 > IDENTIFIER"))
  )
  expect_equal(
    dss_resolve_rows(dss_resolve("CO", con = con, fields = c(name_fields, "ident_upper"))),
    "CO > DTXSID3 > ident_upper"
  )
  expect_equal(
    dss_resolve_rows(dss_resolve(c("CO", "cobalt"), con = con, ignore_case = TRUE, fields = name_fields)),
    sort(c("CO > DTXSID3 > IDENTIFIER", "cobalt > DTXSID3 > IUPAC_NAME", "cobalt > DTXSID3 > PREFERRED_NAME"))
  )
  # With ignore_case, "ident_upper" means the synonym field
  expect_equal(
    dss_resolve_rows(dss_resolve("formalin", con = con, ignore_case = TRUE, fields = "ident_upper")),
    "formalin > DTXSID1 > IDENTIFIER"
  )
  expect_equal(
    dss_resolve_rows(dss_resolve(c("DTXSID1", "CO"), con = con, fields = "DTXSID")),
    sort(c("DTXSID1 > DTXSID1 > DTXSID", "CO > NA > NA"))
  )
})

test_that("dss_resolve() rejects bad options", {
  con <- local_dss_fixture()
  expect_error(dss_resolve("CO", con = con, fields = "EVIL_COL"), "Invalid field")
  expect_error(dss_resolve("CO", con = con, fields = character(0)), "fields")
  expect_error(dss_resolve("CO", con = con, fields = NA_character_), "fields")
  expect_error(dss_resolve("CO", con = con, fields = 1), "fields")
  expect_error(dss_resolve("CO", con = con, ignore_case = NA), "ignore_case")
})
