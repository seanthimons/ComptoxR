#!/usr/bin/env Rscript
check_hook_config <- function(root = '.') {
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
  wrappers <- list()
  for (file in list.files(file.path(root, 'R'), '\\.R$', full.names = TRUE)) {
    for (expression in parse(file, keep.source = FALSE)) {
      if (
        is.call(expression) &&
          identical(expression[[1]], as.name('<-')) &&
          is.call(expression[[3]]) &&
          identical(expression[[3]][[1]], as.name('function'))
      ) {
        wrappers[[as.character(expression[[2]])]] <- eval(expression[[3]], envir = hooks)
      }
    }
  }
  result <- wrapmaint::validate_hooks(config, wrappers, hooks)
  if (!result$valid) {
    stop(paste(result$errors, collapse = '\n'), call. = FALSE)
  }
  message(sprintf(
    'Hook config validation passed: %d function(s), %d hook(s), %d extra param(s)',
    result$functions,
    result$hooks,
    result$parameters
  ))
  invisible(result)
}
if (sys.nframe() == 0L) {
  check_hook_config()
}
