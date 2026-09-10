#!/usr/bin/env Rscript
.gaps_root <- specmill::script_root('detect_test_gaps.R')
detect_gaps <- function(root = .gaps_root, mode = c('apply', 'plan')) {
  callbacks <- new.env(parent = baseenv())
  sys.source(file.path(root, 'dev/specmill_callbacks.R'), envir = callbacks)
  specmill::test_gap_report(
    root,
    file.path(root, 'dev/specmill-testing.yml'),
    callbacks = callbacks,
    mode = match.arg(mode)
  )
}
if (sys.nframe() == 0L) {
  detect_gaps()
}
