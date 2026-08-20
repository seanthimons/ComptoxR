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

test_that("server helpers return URLs without changing process state", {
  withr::local_envvar(c(
    ctx_burl = "ctx-sentinel",
    chemi_burl = "chemi-sentinel",
    epi_burl = "epi-sentinel",
    eco_burl = "eco-sentinel",
    toxval_burl = "toxval-sentinel",
    np_burl = "np-sentinel",
    pubchem_burl = "pubchem-sentinel"
  ))

  cases <- list(
    list(ctx_server, 2, "ctx_burl", "https://ctx-api-stg.ccte.epa.gov/"),
    list(chemi_server, 2, "chemi_burl", "https://cim.sciencedataexperts.com/api"),
    list(epi_server, 1, "epi_burl", "https://episuite.dev/EpiWebSuite/api"),
    list(eco_server, 2, "eco_burl", "http://127.0.0.1:5555"),
    list(toxval_server, 2, "toxval_burl", "http://127.0.0.1:5556"),
    list(np_server, 1, "np_burl", "https://api.naturalproducts.net/latest/"),
    list(pubchem_server, 1, "pubchem_burl", "https://pubchem.ncbi.nlm.nih.gov/rest/pug/")
  )

  for (case in cases) {
    expect_identical(case[[1]](case[[2]], url_only = TRUE), case[[4]])
    expect_match(Sys.getenv(case[[3]]), "-sentinel$")
  }

  expect_identical(chemi_server(NULL, url_only = TRUE), "")
  expect_identical(suppressMessages(chemi_server(99, url_only = TRUE)), "")
  expect_identical(Sys.getenv("chemi_burl"), "chemi-sentinel")
  expect_error(chemi_server(1, url_only = NA), "url_only")
})

test_that("database server URL lookup does not close cached connections", {
  eco_closed <- FALSE
  toxval_closed <- FALSE
  local_mocked_bindings(
    .eco_close_con = function() {
      eco_closed <<- TRUE
    },
    .tox_close_con = function() {
      toxval_closed <<- TRUE
    },
    .package = "ComptoxR"
  )

  expect_identical(eco_server(3, url_only = TRUE), "https://cfpub.epa.gov/ecotox/index.cfm")
  expect_identical(
    toxval_server(3, url_only = TRUE),
    "https://comptox.epa.gov/dashboard/chemical-lists/TOXVAL"
  )
  expect_false(eco_closed)
  expect_false(toxval_closed)
})

test_that("run_verbose and run_setup have offline-safe configuration contracts", {
  withr::local_envvar(c(
    ctx_burl = "",
    chemi_burl = "",
    epi_burl = "",
    pubchem_burl = "",
    eco_burl = "",
    toxval_burl = "",
    ctx_api_key = ""
  ))
  withr::local_options(list(ComptoxR.run_verbose = NULL))

  suppressMessages(run_verbose(TRUE))
  expect_identical(getOption("ComptoxR.run_verbose"), TRUE)
  suppressMessages(run_verbose("invalid"))
  expect_identical(getOption("ComptoxR.run_verbose"), FALSE)

  expect_null(suppressWarnings(suppressMessages(run_setup())))
})

test_that("CAS coercion helper handles valid and invalid input", {
  expect_equal(
    as_cas(c("CAS: 7732-18-5", "50000", "50-00-1", NA)),
    c("7732-18-5", "50-00-0", NA_character_, NA_character_)
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

  expect_error(chemi_functional_use(numeric()), "non-empty character vector")
  expect_error(chemi_predict(NULL), "Request missing")
  expect_error(chemi_safety_section(query = "DTXSID7020182"), "Missing section")
  expect_error(util_classyfire(), "query")
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
