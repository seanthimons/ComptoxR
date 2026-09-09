#!/usr/bin/env Rscript
.stubs_root <- apipak::script_root('generate_stubs.R')
generate_stubs_main <- function(root = .stubs_root, args = commandArgs(trailingOnly = TRUE)) {
  callbacks <- new.env(parent = baseenv())
  sys.source(file.path(root, 'dev/apipak_callbacks.R'), envir = callbacks)
  apipak::generation_command(root, args, 'stubs', callbacks = callbacks)
}
if (sys.nframe() == 0L) {
  generate_stubs_main()
}
