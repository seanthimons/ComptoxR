# Regression coverage for tests that depend on source-tree-only files.

cran_tarball_dependency_lines <- function(file) {
  lines <- readLines(file, warn = FALSE)
  code_lines <- !grepl("^\\s*#", lines)
  excluded_path_literal <- "[\"'](?:dev|data-raw)(?:[/\\\\]|[\"'])"
  repo_path_context <- paste(
    "\\bsource\\s*\\(",
    "\\bhere::here\\s*\\(",
    "\\btestthat::test_path\\s*\\(",
    "\\bproject_path\\s*\\(",
    "\\blifestage_project_file\\s*\\(",
    sep = "|"
  )
  path_lines <- which(code_lines & grepl(excluded_path_literal, lines, perl = TRUE))

  path_lines[vapply(
    path_lines,
    function(line_number) {
      context <- paste(lines[max(1L, line_number - 4L):line_number], collapse = "\n")
      grepl(repo_path_context, context, perl = TRUE)
    },
    logical(1)
  )]
}

cran_tarball_guard_present <- function(lines, line_number) {
  guard_window <- paste(
    lines[max(1L, line_number - 4L):min(length(lines), line_number + 8L)],
    collapse = "\n"
  )
  has_skip <- grepl(
    "testthat::skip(?:_if|_if_not)?\\s*\\(|\\bskip(?:_if|_if_not)?\\s*\\(",
    guard_window,
    perl = TRUE
  )
  has_file_check <- grepl("file\\.exists\\s*\\(", guard_window, perl = TRUE)
  has_clear_reason <- grepl(
    "maintainer|CRAN source tarball|CRAN tarball|[.]Rbuildignore|excluded|not available",
    guard_window,
    ignore.case = TRUE,
    perl = TRUE
  )

  has_skip && has_file_check && has_clear_reason
}

test_that("source-tree-only test dependencies have CRAN-tarball guards", {
  test_dir <- testthat::test_path()
  test_files <- normalizePath(
    list.files(test_dir, pattern = "^test-.*[.]R$", full.names = TRUE),
    winslash = "/",
    mustWork = TRUE
  )
  current_file <- normalizePath(
    testthat::test_path("test-cran_tarball_test_paths.R"),
    winslash = "/",
    mustWork = FALSE
  )
  test_files <- setdiff(test_files, current_file)

  failures <- unlist(
    lapply(test_files, function(file) {
      lines <- readLines(file, warn = FALSE)
      dependency_lines <- cran_tarball_dependency_lines(file)
      unguarded <- dependency_lines[
        !vapply(
          dependency_lines,
          function(line_number) cran_tarball_guard_present(lines, line_number),
          logical(1)
        )
      ]

      sprintf(
        "tests/testthat/%s:%d needs a file.exists() skip with maintainer/CRAN-tarball reason",
        basename(file),
        unguarded
      )
    }),
    use.names = FALSE
  )

  testthat::expect_equal(failures, character())
})
