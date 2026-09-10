#!/usr/bin/env Rscript
.tests_root <- specmill::script_root('generate_tests.R')
generate_tests_main <- function(args = commandArgs(trailingOnly = TRUE), root = .tests_root) {
  callbacks <- new.env(parent = baseenv())
  sys.source(file.path(root, 'dev/specmill_callbacks.R'), envir = callbacks)
  specmill::generation_command(root, args, 'tests', callbacks = callbacks)
}
if (sys.nframe() == 0L) {
  generate_tests_main()
}
