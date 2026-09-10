#!/usr/bin/env Rscript
.coverage_root <- specmill::script_root('calculate_coverage.R')
calculate_coverage <- function(root = .coverage_root, mode = c('apply', 'plan')) {
  callbacks <- new.env(parent = baseenv())
  sys.source(file.path(root, 'dev/specmill_callbacks.R'), envir = callbacks)
  specmill::coverage_report(
    root,
    file.path(root, 'dev/specmill-coverage.yml'),
    callbacks = callbacks,
    mode = match.arg(mode)
  )
}
if (sys.nframe() == 0L) {
  calculate_coverage()
}
