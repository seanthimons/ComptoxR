# Integration test for the offline CTX mock (inst/plumber/ctx/plumber.R).
# Runs real ct_*() calls against a live Plumber process on the local DSSTox db.

test_that("ct_*() identifier functions work against the offline CTX mock", {
  skip_if_integration_only()
  skip_if_not_installed("plumber")
  skip_if_not_installed("callr")
  skip_if_no_local_db_at(dss_path(), "DSSTox database")

  port <- 5557L
  api <- system.file("plumber", "ctx", "plumber.R", package = "ComptoxR")
  proc <- callr::r_bg(
    function(api, port, db) {
      options(ComptoxR.dsstox_path = db)
      plumber::pr_run(plumber::pr(api), port = port, docs = FALSE, quiet = TRUE)
    },
    args = list(api = api, port = port, db = dss_path())
  )
  withr::defer(proc$kill())

  base <- sprintf("http://127.0.0.1:%d/", port)
  # Table build takes ~20-30s on the full DSSTox db.
  up <- FALSE
  for (i in 1:90) {
    up <- tryCatch(httr2::resp_status(httr2::req_perform(httr2::request(paste0(base, "chemical/health")))) == 200L,
                   error = function(e) FALSE)
    if (up || !proc$is_alive()) break
    Sys.sleep(1)
  }
  expect_true(up, info = proc$read_all_error())

  withr::local_envvar(ctx_api_key = "offline")
  withr::local_options(ComptoxR.ctx_burl = base)

  detail <- ct_chemical_detail_search("DTXSID7020182")
  expect_identical(detail$casrn, "80-05-7")
  expect_true("averageMass" %in% names(detail))
  expect_error(ct_chemical_detail_search("DTXSID000"), "400")

  bulk <- ct_chemical_detail_search_bulk(c("DTXSID7020182", "DTXSID000", "DTXSID2021315"))
  expect_identical(bulk$dtxsid, c("DTXSID2021315", "DTXSID7020182"))

  expect_identical(ct_chemical_search_equal("Bisphenol A")$dtxsid, "DTXSID7020182")
  expect_identical(ct_chemical_search_equal("0080-05-7")$searchName, "CASRN")

  batch <- ct_chemical_search_equal_bulk(c("80-05-7", "no such chemical"))
  expect_identical(batch$dtxsid, c("DTXSID7020182", NA))

  expect_identical(ct_chemical_search_start_with("atrazine", top = 5)$dtxsid[1], "DTXSID9020112")
  expect_lte(nrow(ct_chemical_search_contain("atrazine", top = 5)), 5)

  syn <- ct_chemical_synonym_search_bulk(c("DTXSID7020182", "DTXSID000"))
  expect_identical(syn$dtxsid, "DTXSID7020182")

  unsupported <- httr2::req_perform(
    httr2::req_error(httr2::request(paste0(base, "hazard/toxval/search/by-dtxsid/DTXSID7020182")), is_error = function(r) FALSE)
  )
  expect_identical(httr2::resp_status(unsupported), 404L)
})
