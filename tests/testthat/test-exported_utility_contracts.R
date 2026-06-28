test_that("server helpers set and reset exported API base URLs", {
  withr::local_envvar(c(
    ctx_burl = "",
    chemi_burl = "",
    epi_burl = "",
    pubchem_burl = ""
  ))

  suppressMessages(ctx_server(1))
  expect_equal(Sys.getenv("ctx_burl"), "https://comptox.epa.gov/ctx-api/")
  suppressMessages(ctx_server(NULL))
  expect_equal(Sys.getenv("ctx_burl"), "")

  suppressMessages(chemi_server(1))
  expect_equal(Sys.getenv("chemi_burl"), "https://hcd.rtpnc.epa.gov/api")
  suppressMessages(chemi_server(NULL))
  expect_equal(Sys.getenv("chemi_burl"), "")

  suppressMessages(epi_server(1))
  expect_equal(Sys.getenv("epi_burl"), "https://episuite.dev/EpiWebSuite/api")
  suppressMessages(epi_server(NULL))
  expect_equal(Sys.getenv("epi_burl"), "")

  suppressMessages(pubchem_server(1))
  expect_equal(Sys.getenv("pubchem_burl"), "https://pubchem.ncbi.nlm.nih.gov/rest/pug/")
  suppressMessages(pubchem_server(NULL))
  expect_equal(Sys.getenv("pubchem_burl"), "")
})

test_that("run_verbose and run_setup have offline-safe configuration contracts", {
  withr::local_envvar(c(
    run_verbose = "",
    ctx_burl = "",
    chemi_burl = "",
    epi_burl = "",
    pubchem_burl = "",
    eco_burl = "",
    toxval_burl = "",
    ctx_api_key = ""
  ))

  suppressMessages(run_verbose(TRUE))
  expect_equal(Sys.getenv("run_verbose"), "TRUE")
  suppressMessages(run_verbose("invalid"))
  expect_equal(Sys.getenv("run_verbose"), "FALSE")

  expect_null(suppressWarnings(suppressMessages(run_setup())))
})

test_that("CAS and text extraction helpers handle valid and invalid input", {
  expect_equal(
    as_cas(c("CAS: 7732-18-5", "50000", "50-00-1", NA)),
    c("7732-18-5", "50-00-0", NA_character_, NA_character_)
  )

  extracted <- extract_cas(c(
    "The CAS numbers are 50-00-0 and 7732-18-5.",
    "Invalid 50-00-1 should not be returned."
  ))
  expect_equal(extracted[[1]], c("50-00-0", "7732-18-5"))
  expect_equal(extracted[[2]], character(0))

  formulas <- extract_formulas(c(
    "Water (H2O) and sodium chloride (NaCl).",
    "Iron (III) chloride should not treat III as a formula."
  ))
  expect_equal(formulas[[1]], c("H2O", "NaCl"))
  expect_equal(formulas[[2]], character(0))

  expect_equal(
    extract_mixture(c("Blend (1:1)", "Single chemical", "Blend 1.5:1 w/w")),
    c(TRUE, FALSE, TRUE)
  )
})

test_that("small numeric and message formatting helpers keep their contracts", {
  expect_equal(min2(c(NA, 3, 1)), 1)
  expect_true(is.na(min2(c(NA_real_, NA_real_))))
  expect_equal(geometric.mean(c(1, 4, NA)), 2)

  expect_message(pretty_list(c("alpha", "beta")), '"alpha",')
  expect_message(pretty_print("alpha"), "alpha")
  expect_message(pretty_rename("field"), "'' = 'field'")
  expect_message(pretty_casewhen("x", 1), "x == 1")
})

test_that("API helper exports validate before external work", {
  withr::local_envvar(c(ctx_api_key = ""))
  expect_error(ct_api_key(), "No CTX API key")
  withr::local_envvar(c(ctx_api_key = "real-token"))
  expect_equal(ct_api_key(), "real-token")

  expect_error(chemi_cluster("DTXSID7020182", sort = NULL), "Missing sort")
  expect_error(chemi_functional_use(numeric()), "non-empty character vector")
  expect_error(chemi_predict(NULL), "Request missing")
  expect_error(chemi_safety_section(query = "DTXSID7020182"), "Missing section")
  expect_error(epi_suite_pull_data(list()), "Missing aggregaion endpoint")
  expect_error(util_classyfire(), "query")
})

test_that("chemi_cluster_sim_list converts similarity matrices to long form", {
  cluster <- list(
    mol_names = tibble::tibble(name = c("A", "B")),
    similarity = list(c(1, 0.25), c(0.25, 1))
  )

  result <- chemi_cluster_sim_list(cluster)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(sort(result$value), c(0.25, 0.25))
  expect_true(all(result$parent != result$child))
})

test_that("ct_classify adds classification fields without network access", {
  input <- tibble::tibble(
    molFormula = c("C6H6", "NaCl", "[13C]"),
    preferredName = c("Benzene", "Sodium chloride", "Carbon-13"),
    dtxsid = c("DTXSID1", "DTXSID2", "DTXSID3"),
    smiles = c("c1ccccc1", "[Na+].[Cl-]", "[13C]"),
    isMarkush = c(FALSE, FALSE, FALSE),
    isotope = c(0L, 0L, 1L),
    multicomponent = c(0L, 1L, 0L),
    inchiString = c("", "", "")
  )

  result <- ct_classify(input)

  expect_true(all(c("class", "super_class", "composition") %in% names(result)))
  expect_equal(nrow(result), nrow(input))
  expect_equal(result$super_class[[1]], "Organic compounds")
  expect_equal(result$composition[[2]], "MIXTURE")
})

test_that("dss_install can install from a local source file", {
  source <- tempfile(fileext = ".duckdb")
  dest <- tempfile(fileext = ".duckdb")
  writeBin(as.raw(c(1, 2, 3)), source)
  withr::local_options(list(ComptoxR.dsstox_path = dest))
  on.exit(unlink(c(source, dest)), add = TRUE)

  installed <- dss_install(source = source, overwrite = TRUE)

  expect_equal(installed, dest)
  expect_true(file.exists(dest))
  expect_equal(readBin(dest, "raw", n = 3), as.raw(c(1, 2, 3)))
})
