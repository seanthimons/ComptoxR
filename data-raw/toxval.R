# ToxValDB Build Entry Point
# -------------------------------------------------------------------
# Run this script to build the ToxValDB DuckDB database from source.
# Requires: readxl, janitor, httr2 (listed in Suggests)
#
# Usage:
#   source("data-raw/toxval.R")

.toxval_build_script <- function() {
  dev_path <- file.path(getwd(), "inst", "toxval", "toxval_build.R")
  if (file.exists(dev_path)) {
    return(dev_path)
  }

  installed_path <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
  if (nzchar(installed_path) && file.exists(installed_path)) {
    return(installed_path)
  }

  cli::cli_abort(c(
    "ToxValDB build script not found.",
    "i" = "Run this launcher from a development checkout or install ComptoxR with its inst/toxval assets."
  ))
}

source(.toxval_build_script(), local = new.env(parent = globalenv()))
