# ToxValDB Build Entry Point
# -------------------------------------------------------------------
# Run this script to build the ToxValDB DuckDB database from source.
# Requires: readxl, janitor, httr2 (listed in Suggests)
#
# Usage:
#   source("data-raw/toxval.R")

source(system.file("toxval", "toxval_build.R", package = "ComptoxR"))
.build_toxval_db()
