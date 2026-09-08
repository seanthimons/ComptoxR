test_that("ECOTOX queries ignore absent, present, and stale derived tables", {
  path <- make_source_ecotox_db(c("Adult", "Unresolved", NA_character_))
  withr::defer(unlink(path))
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))
  withr::local_envvar(c(eco_burl = path))

  tests <- DBI::dbReadTable(con, "tests")[rep(1L, 5L), ]
  tests$test_id <- seq_len(5L)
  tests$organism_lifestage <- c("L001", "L002", "L003", "missing", "L001")
  results <- DBI::dbReadTable(con, "results")[rep(1L, 5L), ]
  results$test_id <- results$result_id <- seq_len(5L)
  DBI::dbWriteTable(con, "tests", tests, overwrite = TRUE)
  DBI::dbWriteTable(con, "results", results, overwrite = TRUE)

  query <- function() dplyr::arrange(eco_results(casrn = "50-29-3", con = con), .data$result_id)
  expected <- query()
  expect_equal(expected$organism_lifestage, tests$organism_lifestage)
  expect_equal(expected$org_lifestage, c("Adult", "Unresolved", NA, NA, "Adult"))
  expect_false(any(c("harmonized_life_stage", "reproductive_stage") %in% names(expected)))
  expect_error(eco_results(casrn = "50-29-3", lifestage_details = TRUE, con = con), "unused argument")

  derived <- data.frame(org_lifestage = c("Adult", "Adult"), harmonized_life_stage = "wrong", reproductive_stage = TRUE)
  DBI::dbWriteTable(con, "lifestage_dictionary", derived)
  DBI::dbWriteTable(con, "lifestage_review", derived)
  expect_identical(query(), expected)
  expect_identical(DBI::dbReadTable(con, "lifestage_dictionary"), derived)
  DBI::dbWriteTable(con, "lifestage_dictionary", data.frame(stale = 1L), overwrite = TRUE)
  expect_identical(query(), expected)
  expect_identical(DBI::dbReadTable(con, "lifestage_dictionary"), data.frame(stale = 1L))
})

test_that("both ECOTOX builders have no harmonizer dependency and propagate failures", {
  installed <- system.file("ecotox", "ecotox_build.R", package = "ComptoxR")
  source <- testthat::test_path("..", "..", "inst", "ecotox", "ecotox_build.R")
  if (file.exists(source)) {
    installed <- source
  }
  paths <- c(installed, testthat::test_path("..", "..", "data-raw", "ecotox.R"))
  paths <- paths[file.exists(paths)]
  expect_gte(length(paths), 1L)
  builders <- lapply(paths, function(path) {
    exprs <- parse(path)
    expect_identical(tail(exprs, 1L)[[1]], quote(.build_ecotox_db()))
    env <- new.env(parent = globalenv())
    for (expr in head(exprs, -1L)) {
      eval(expr, env)
    }
    code <- paste(deparse(env$.build_ecotox_db), collapse = "\n")
    expect_false(grepl("lifestage_dictionary|lifestage_review|eco_lifestage", code))
    env$.build_ecotox_db <- function() stop("ordinary build failure")
    expect_error(eval(tail(exprs, 1L)[[1]], env), "ordinary build failure")
    code
  })
})

test_that("shipped localhost Plumber results match direct source-only queries", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("callr")
  path <- make_source_ecotox_db(NA_character_)
  withr::defer(unlink(path))
  withr::local_envvar(c(eco_burl = path))
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
  direct <- eco_results(casrn = "50-29-3", con = con)
  DBI::dbDisconnect(con, shutdown = TRUE)
  script <- system.file("plumber", "ecotox", "plumber.R", package = "ComptoxR")
  port <- httpuv::randomPort()
  package_path <- system.file(package = "ComptoxR")
  source_path <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
  from_source <- file.exists(file.path(source_path, "R", "eco_functions.R"))
  if (from_source) {
    package_path <- source_path
    script <- file.path(source_path, "inst", "plumber", "ecotox", "plumber.R")
  }
  server <- callr::r_bg(
    function(path, script, port, package_path) {
      if (file.exists(file.path(package_path, "R", "eco_functions.R"))) {
        pkgload::load_all(package_path, quiet = TRUE)
      }
      options(ComptoxR.ecotox_path = path)
      plumber::pr_run(plumber::pr(script), host = "127.0.0.1", port = port)
    },
    args = list(path, script, port, package_path)
  )
  withr::defer(server$kill())
  url <- paste0("http://127.0.0.1:", port)
  ready <- FALSE
  for (i in seq_len(100L)) {
    ready <- tryCatch(
      {
        httr2::request(paste0(url, "/health-check")) |>
          httr2::req_timeout(1) |>
          httr2::req_perform()
        TRUE
      },
      error = function(e) FALSE
    )
    if (ready || !server$is_alive()) {
      break
    }
    Sys.sleep(0.1)
  }
  expect_true(ready, info = paste(server$read_error_lines(), collapse = "\n"))
  if (!ready) {
    return(invisible(NULL))
  }
  Sys.setenv(eco_burl = url)
  remote <- tryCatch(eco_results(casrn = "50-29-3"), error = function(e) {
    stop(paste(conditionMessage(e), paste(c(server$read_error_lines(), server$read_output_lines()), collapse = "\n")))
  })
  expect_identical(names(remote), names(direct))
  expect_equal(lapply(remote, as.character), lapply(direct, as.character))
  expect_equal(nrow(remote), nrow(direct))
  expect_equal(remote$organism_lifestage, direct$organism_lifestage)
  expect_equal(as.character(remote$org_lifestage), direct$org_lifestage)
  expect_equal(remote$final_conc, direct$final_conc)
  expect_false(any(c("harmonized_life_stage", "reproductive_stage") %in% names(remote)))
  empty <- eco_results(casrn = "not-in-fixture")
  expect_equal(nrow(empty), 0L)
  expect_identical(names(empty), names(direct))
})

test_that("both builders import local source data without mapping artifacts", {
  if (.Platform$OS.type == "windows") {
    withr::local_locale(c(LC_CTYPE = ".UTF-8"))
  }
  for (pkg in c("arrow", "janitor", "lubridate", "readr", "readxl", "rvest")) {
    skip_if_not_installed(pkg)
  }
  fixture <- make_source_ecotox_db("New unmapped source term")
  withr::defer(unlink(fixture))
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = fixture, read_only = TRUE)
  base_names <- c("tests", "results", "species", "chemicals", "lifestage_codes")
  tables <- setNames(lapply(base_names, function(x) DBI::dbReadTable(con, x)), base_names)
  app_names <- c(
    "app_exposure_types",
    "app_exposure_type_groups",
    "app_effect_groups_and_measurements",
    "app_application_frequencies"
  )
  appendix <- setNames(lapply(app_names, function(x) DBI::dbReadTable(con, x)), sub("app_", "", app_names))
  DBI::dbDisconnect(con, shutdown = TRUE)
  tables$tests$organism_habitat <- "water"
  tables$species$ecotox_group <- "Fish"
  tables$references <- data.frame(reference_number = 1L, publication_year = "2026")
  tables$duration_unit_codes <- data.frame(code = "h", description = "hours")
  appendix$effect_groups <- data.frame(group_effect_term_s = "MOR", description = "Mortality", definition = "Mortality")
  # Preserve optional fixture columns through the builder's empty-column removal.
  tables <- lapply(tables, function(tbl) {
    tbl[] <- lapply(tbl, function(x) {
      x <- as.character(x)
      x[is.na(x)] <- "0"
      x
    })
    tbl
  })
  release <- "ecotox_ascii_03_12_2026.zip"
  html <- paste0('<a href="', release, '">source</a><a href="appendix.xlsx">appendix</a>')
  testthat::local_mocked_bindings(
    req_perform = function(...) TRUE,
    resp_body_string = function(...) html,
    .package = "httr2"
  )
  testthat::local_mocked_bindings(
    unzip = function(zipfile, exdir, ...) {
      ascii <- file.path(exdir, "ecotox_ascii_03_12_2026")
      dir.create(ascii)
      for (nm in names(tables)) {
        readr::write_delim(tables[[nm]], file.path(ascii, paste0(nm, ".txt")), delim = "|")
      }
      invisible(NULL)
    },
    .package = "utils"
  )
  testthat::local_mocked_bindings(
    excel_sheets = function(...) c("Contents", names(appendix)),
    read_excel = function(path, sheet, ...) {
      if (sheet == "Contents") data.frame(Title = names(appendix)) else appendix[[sheet]]
    },
    .package = "readxl"
  )
  output_dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(R_user_dir = function(...) output_dir, .package = "tools")
  withr::local_envvar(c(COMPTOXR_ECOTOX_RELEASE_ZIP = release))
  installed <- system.file("ecotox", "ecotox_build.R", package = "ComptoxR")
  source <- testthat::test_path("..", "..", "inst", "ecotox", "ecotox_build.R")
  if (file.exists(source)) {
    installed <- source
  }
  paths <- c(installed, testthat::test_path("..", "..", "data-raw", "ecotox.R"))
  for (path in paths[file.exists(paths)]) {
    output_dir <- tempfile("source-only-build-")
    withr::defer(unlink(output_dir, recursive = TRUE))
    env <- new.env(parent = globalenv())
    env$download.file <- function(...) invisible(0L)
    sys.source(path, env)
    built <- file.path(output_dir, "ecotox.duckdb")
    expect_true(file.exists(built))
    built_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = built, read_only = TRUE)
    tryCatch(
      {
        expect_false(any(c("lifestage_dictionary", "lifestage_review") %in% DBI::dbListTables(built_con)))
        withr::with_envvar(c(eco_burl = built), {
          result <- eco_results(casrn = "50-29-3", con = built_con)
          expect_equal(result$org_lifestage, "New unmapped source term")
          expect_equal(result$organism_lifestage, "L001")
        })
      },
      finally = DBI::dbDisconnect(built_con, shutdown = TRUE)
    )
  }
})
