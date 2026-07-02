# Tests for release database asset workflow launchers

asset_project_root <- function() {
  cwd <- getwd()
  if (file.exists(file.path(cwd, "DESCRIPTION")) && dir.exists(file.path(cwd, "R"))) {
    return(normalizePath(cwd, winslash = "/"))
  }

  root <- testthat::test_path("..", "..")
  if (file.exists(file.path(root, "DESCRIPTION")) && dir.exists(file.path(root, "R"))) {
    return(normalizePath(root, winslash = "/"))
  }

  normalizePath(getwd(), winslash = "/")
}

asset_project_path <- function(...) {
  file.path(asset_project_root(), ...)
}

asset_load_defs <- function(path, skip_calls) {
  env <- new.env(parent = globalenv())
  for (expr in parse(path)) {
    if (is.call(expr)) {
      call_name <- as.character(expr[[1]])[1]
      if (call_name %in% skip_calls) {
        next
      }
    }
    eval(expr, envir = env)
  }
  env
}

ecotox_build_script_path <- function() {
  source_path <- asset_project_path("inst", "ecotox", "ecotox_build.R")
  if (file.exists(source_path)) {
    return(source_path)
  }

  installed_path <- system.file("ecotox", "ecotox_build.R", package = "ComptoxR")
  testthat::skip_if(!nzchar(installed_path), "ECOTOX build script not available")
  installed_path
}

test_that("ToxVal data-raw launcher resolves the checkout build script", {
  launcher <- asset_project_path("data-raw", "toxval.R")
  testthat::skip_if_not(file.exists(launcher), "data-raw launcher is excluded from source tarballs")

  withr::local_dir(asset_project_root())
  env <- asset_load_defs(launcher, skip_calls = "source")
  expected <- asset_project_path("inst", "toxval", "toxval_build.R")

  testthat::expect_equal(
    normalizePath(env$.toxval_build_script(), winslash = "/"),
    normalizePath(expected, winslash = "/")
  )
})

test_that("ECOTOX release selector defaults to the newest ASCII release", {
  testthat::skip_if_not_installed("lubridate")
  testthat::skip_if_not_installed("stringr")
  env <- asset_load_defs(ecotox_build_script_path(), skip_calls = ".build_ecotox_db")
  withr::local_envvar(c(COMPTOXR_ECOTOX_RELEASE_ZIP = NA))

  selected <- env$.ecotox_select_ascii_zip(c(
    "ecotox_ascii_03_12_2026.zip",
    "ecotox_ascii_06_11_2026.zip"
  ))

  testthat::expect_equal(selected$file, "ecotox_ascii_06_11_2026.zip")
  testthat::expect_equal(as.character(selected$date), "2026-06-11")
  testthat::expect_false(selected$requested)
})

test_that("ECOTOX release selector honors explicit asset workflow release", {
  testthat::skip_if_not_installed("lubridate")
  testthat::skip_if_not_installed("stringr")
  env <- asset_load_defs(ecotox_build_script_path(), skip_calls = ".build_ecotox_db")
  withr::local_envvar(c(COMPTOXR_ECOTOX_RELEASE_ZIP = "ecotox_ascii_03_12_2026.zip"))

  selected <- env$.ecotox_select_ascii_zip(c(
    "ecotox_ascii_03_12_2026.zip",
    "ecotox_ascii_06_11_2026.zip"
  ))

  testthat::expect_equal(selected$file, "ecotox_ascii_03_12_2026.zip")
  testthat::expect_equal(as.character(selected$date), "2026-03-12")
  testthat::expect_true(selected$requested)
})

test_that("ECOTOX release selector rejects a missing explicit release", {
  testthat::skip_if_not_installed("lubridate")
  testthat::skip_if_not_installed("stringr")
  env <- asset_load_defs(ecotox_build_script_path(), skip_calls = ".build_ecotox_db")
  withr::local_envvar(c(COMPTOXR_ECOTOX_RELEASE_ZIP = "ecotox_ascii_03_12_2026.zip"))

  testthat::expect_error(
    env$.ecotox_select_ascii_zip("ecotox_ascii_06_11_2026.zip"),
    "Requested ECOTOX release was not found"
  )
})
