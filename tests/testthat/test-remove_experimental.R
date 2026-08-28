test_that("experimental remover filters by endpoint prefix", {
  remover <- testthat::test_path("..", "..", "dev", "remove_experimental.R")
  testthat::skip_if_not(file.exists(remover), "Maintainer-only test requires dev scripts")
  source(remover, local = TRUE)

  root <- withr::local_tempdir()
  r_dir <- file.path(root, "R")
  dir.create(r_dir)
  wrapper <- function(name, lifecycle = NULL, stage = "public") {
    c(
      paste0("#' ", name),
      if (!is.null(lifecycle)) paste0("#' `r lifecycle::badge(\"", lifecycle, "\")`"),
      if (!is.null(stage)) paste0("#' @apiStage ", stage),
      "#' @export",
      paste0(name, " <- function() NULL")
    )
  }

  writeLines(wrapper("chemi_selected", "experimental"), file.path(r_dir, "chemi_selected.R"))
  writeLines(wrapper("ct_selected", "experimental"), file.path(r_dir, "ct_selected.R"))
  writeLines(wrapper("cts_not_ct", "experimental"), file.path(r_dir, "cts_not_ct.R"))
  writeLines(wrapper("chemi_amos_method", "experimental"), file.path(r_dir, "chemi_amos_method.R"))
  writeLines(wrapper("chemi_amos_method_list", "experimental"), file.path(r_dir, "chemi_amos_method_list.R"))
  writeLines(wrapper("chemi_amos_other", "experimental"), file.path(r_dir, "chemi_amos_other.R"))
  writeLines(wrapper("chemi_stable", "stable"), file.path(r_dir, "chemi_stable.R"))
  writeLines(wrapper("chemi_maturing", "maturing"), file.path(r_dir, "chemi_maturing.R"))
  writeLines(wrapper("chemi_untagged", NULL), file.path(r_dir, "chemi_untagged.R"))
  writeLines(
    c(wrapper("chemi_mixed", "experimental"), "", wrapper("chemi_mixed_bulk", "stable")),
    file.path(r_dir, "chemi_mixed.R")
  )

  report <- scan_experimental_files(r_dir)
  expect_setequal(
    basename(report$file[report$status == "selected"]),
    c(
      "chemi_selected.R",
      "chemi_amos_method.R",
      "chemi_amos_method_list.R",
      "chemi_amos_other.R"
    )
  )
  expect_false("ct_selected.R" %in% basename(report$file))
  expect_true(all(
    paste0("chemi_", c("stable", "maturing", "untagged", "mixed"), ".R") %in%
      basename(report$file[report$status != "selected"])
  ))

  ct_report <- scan_experimental_files(r_dir, prefix = "ct")
  expect_identical(basename(ct_report$file), "ct_selected.R")

  method_report <- scan_experimental_files(r_dir, prefix = "chemi_amos_method")
  expect_setequal(
    basename(method_report$file),
    c("chemi_amos_method.R", "chemi_amos_method_list.R")
  )
})

test_that("experimental remover defaults to a Cheminformatics dry-run", {
  remover <- testthat::test_path("..", "..", "dev", "remove_experimental.R")
  testthat::skip_if_not(file.exists(remover), "Maintainer-only test requires dev scripts")
  source(remover, local = TRUE)

  expect_identical(
    parse_remove_args(character()),
    list(
      apply = FALSE,
      help = FALSE,
      prefix = "chemi"
    )
  )
  expect_false(parse_remove_args("--dry-run")$apply)
  expect_true(parse_remove_args(c("--apply", "--prefix=ct"))$apply)
  expect_identical(parse_remove_args("--prefix=ct")$prefix, "ct")
  expect_error(parse_remove_args("--prefix="), "non-empty")
  expect_error(parse_remove_args("--prefix=../R"), "letters, numbers")
  expect_error(scan_experimental_files(tempdir(), prefix = ""), "non-empty")
})

test_that("apply removes only selected files within the endpoint prefix", {
  remover <- testthat::test_path("..", "..", "dev", "remove_experimental.R")
  testthat::skip_if_not(file.exists(remover), "Maintainer-only test requires dev scripts")
  source(remover, local = TRUE)

  root <- withr::local_tempdir()
  r_dir <- file.path(root, "R")
  dir.create(r_dir)
  wrapper <- function(name, lifecycle) {
    c(
      paste0("#' ", name),
      paste0("#' `r lifecycle::badge(\"", lifecycle, "\")`"),
      "#' @apiStage public",
      "#' @export",
      paste0(name, " <- function() NULL")
    )
  }

  selected <- file.path(r_dir, "ct_selected.R")
  protected <- file.path(r_dir, "ct_stable.R")
  adjacent <- file.path(r_dir, "cts_selected.R")
  writeLines(wrapper("ct_selected", "experimental"), selected)
  writeLines(wrapper("ct_stable", "stable"), protected)
  writeLines(wrapper("cts_selected", "experimental"), adjacent)

  withr::local_dir(root)
  expect_output(
    remove_experimental_main(c("--apply", "--prefix=ct")),
    "Removed 1 generated endpoint file"
  )
  expect_false(file.exists(selected))
  expect_true(file.exists(protected))
  expect_true(file.exists(adjacent))
})

test_that("schema updates rebuild experimental API wrappers", {
  workflow <- testthat::test_path("..", "..", ".github", "workflows", "schema-check.yml")
  testthat::skip_if_not(file.exists(workflow), "Maintainer-only test requires workflow files")

  expect_true(any(grepl(
    'remove_experimental_main(c("--apply", "--prefix=ct"))',
    readLines(workflow, warn = FALSE),
    fixed = TRUE
  )))
  expect_true(any(grepl(
    'remove_experimental_main(c("--apply", "--prefix=chemi"))',
    readLines(workflow, warn = FALSE),
    fixed = TRUE
  )))
  expect_true(any(grepl(
    'remove_experimental_main(c("--apply", "--prefix=epi"))',
    readLines(workflow, warn = FALSE),
    fixed = TRUE
  )))
})
