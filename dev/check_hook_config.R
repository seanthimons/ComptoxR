#!/usr/bin/env Rscript
.hook_config_root <- specmill::script_root('check_hook_config.R')
check_hook_config <- function(root = .hook_config_root) {
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  hooks <- new.env(parent = baseenv())
  sys.source(file.path(root, 'R/hook_registry.R'), envir = hooks)
  for (file in list.files(file.path(root, 'R'), '^hooks_.*\\.R$', full.names = TRUE)) {
    sys.source(file, envir = hooks)
  }
  config <- hooks$read_hook_configs(
    file.path(root, 'inst/hook_config.yml'),
    file.path(root, 'inst/hook_config_generated.yml')
  )
  specmill::check_client_hooks(root, config, hooks)
}
if (sys.nframe() == 0L) {
  check_hook_config()
}
