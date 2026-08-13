test_that("experimental remover owns only generated Cheminformatics files", {
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
  writeLines(wrapper("ct_never_selected", "experimental"), file.path(r_dir, "ct_never_selected.R"))
  writeLines(wrapper("chemi_stable", "stable"), file.path(r_dir, "chemi_stable.R"))
  writeLines(wrapper("chemi_maturing", "maturing"), file.path(r_dir, "chemi_maturing.R"))
  writeLines(wrapper("chemi_untagged", NULL), file.path(r_dir, "chemi_untagged.R"))
  writeLines(
    c(wrapper("chemi_mixed", "experimental"), "", wrapper("chemi_mixed_bulk", "stable")),
    file.path(r_dir, "chemi_mixed.R")
  )

  report <- scan_experimental_chemi_files(r_dir)
  expect_identical(basename(report$file[report$status == "selected"]), "chemi_selected.R")
  expect_false("ct_never_selected.R" %in% basename(report$file))
  expect_true(all(
    paste0("chemi_", c("stable", "maturing", "untagged", "mixed"), ".R") %in%
      basename(report$file[report$status != "selected"])
  ))
})

test_that("experimental remover defaults to dry-run and rejects prefix arguments", {
  remover <- testthat::test_path("..", "..", "dev", "remove_experimental.R")
  testthat::skip_if_not(file.exists(remover), "Maintainer-only test requires dev scripts")
  source(remover, local = TRUE)

  expect_false(parse_remove_args(character())$apply)
  expect_false(parse_remove_args("--dry-run")$apply)
  expect_true(parse_remove_args("--apply")$apply)
  expect_error(parse_remove_args("--prefix=ct"), "Unknown argument")
})
