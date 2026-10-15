# Schema coverage badges. Usage: Rscript dev/update_coverage.R [--apply]
source("dev/install_specmill.R", local = TRUE)
verify_specmill()
callbacks <- new.env(parent = baseenv())
sys.source("dev/specmill_callbacks.R", envir = callbacks)
specmill::coverage_report(
  normalizePath("."),
  file.path(normalizePath("."), "dev/coverage.yml"),
  callbacks = callbacks,
  mode = if ("--apply" %in% commandArgs(TRUE)) "apply" else "plan"
)
