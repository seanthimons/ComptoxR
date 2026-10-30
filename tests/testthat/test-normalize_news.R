normalize_news_script <- testthat::test_path("..", "..", "dev", "normalize_news.R")
if (!file.exists(normalize_news_script)) {
  testthat::skip(
    "Maintainer-only test requires dev/normalize_news.R; dev/ is excluded from CRAN source tarballs"
  )
}
source(normalize_news_script)

# What autonewsmd writes: every version section rebuilt from git history.
write_generated_news <- function(path, versions) {
  sections <- lapply(versions, function(v) c(paste0("## ", v, " (2026-11-01)"), "", "#### Other changes", "", "- commit", ""))
  writeLines(c("# NEWS", "", unlist(sections)), path)
}

test_that("hand-written notes survive two releases in a row", {
  path <- withr::local_tempfile(fileext = ".md")
  writeLines(c("# NEWS", "", "## Unreleased", "", "- **Breaking:** renamed.", "", "## v1.0.0", "", "- old"), path)

  notes <- read_release_notes(path)
  write_generated_news(path, c("v2.0.0", "v1.0.0"))
  insert_release_notes(notes, path)
  expect_identical(
    readLines(path)[3:10],
    c(
      "## v2.0.0 (2026-11-01)", "", "#### Release notes", "", "- **Breaking:** renamed.", "",
      "<!-- end release notes -->", ""
    )
  )

  # Next release, with new Unreleased notes added by hand at the top.
  lines <- readLines(path)
  writeLines(c(lines[1:2], "## Unreleased", "", "- Fixed a bug.", "", lines[-(1:2)]), path)
  notes <- read_release_notes(path)
  expect_identical(notes, list(Unreleased = "- Fixed a bug.", v2.0.0 = "- **Breaking:** renamed."))

  write_generated_news(path, c("v2.0.1", "v2.0.0", "v1.0.0"))
  insert_release_notes(notes, path)
  out <- readLines(path)
  expect_identical(out[which(out == "## v2.0.1 (2026-11-01)") + 4L], "- Fixed a bug.")
  expect_identical(out[which(out == "## v2.0.0 (2026-11-01)") + 4L], "- **Breaking:** renamed.")
  expect_identical(read_release_notes(path), list(v2.0.1 = "- Fixed a bug.", v2.0.0 = "- **Breaking:** renamed."))
})

test_that("a NEWS file without hand-written notes is left alone", {
  path <- withr::local_tempfile(fileext = ".md")
  writeLines(c("# NEWS", "", "## Unreleased", "", "## v1.0.0"), path)
  expect_identical(read_release_notes(path), list())
  before <- readLines(path)
  insert_release_notes(list(), path)
  expect_identical(readLines(path), before)
})

test_that("restoring notes into a file without version headings fails clearly", {
  path <- withr::local_tempfile(fileext = ".md")
  writeLines("# NEWS", path)
  expect_error(insert_release_notes(list(Unreleased = "- x"), path), "No version heading")
})
