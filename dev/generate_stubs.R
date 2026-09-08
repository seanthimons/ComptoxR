#!/usr/bin/env Rscript
generate_stubs_main <- function(root = '.', args = commandArgs(trailingOnly = TRUE)) {
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  adapter <- new.env(parent = globalenv())
  sys.source(file.path(root, 'dev/toolkit_adapter.R'), envir = adapter)
  mode <- if ('--check' %in% args) {
    'check'
  } else if ('--plan' %in% args) {
    'plan'
  } else {
    'apply'
  }
  rebuild <- sub('^--rebuild=', '', grep('^--rebuild=', args, value = TRUE))
  result <- adapter$generate_comptox(root, mode, rebuild)
  actions <- vapply(result$files, `[[`, character(1), 'action')
  print(table(actions))
  if (mode == 'check' && any(actions %in% c('write', 'remove'))) {
    stop('Generated wrappers are not current')
  }
  if (mode == 'apply' && nzchar(Sys.getenv('GITHUB_OUTPUT'))) {
    scaffold <- dplyr::bind_rows(lapply(result$results, `[[`, 'scaffold'))
    drift <- dplyr::bind_rows(lapply(result$results, `[[`, 'drift'))
    created <- sum(scaffold$action == 'created')
    appended <- sum(scaffold$action == 'appended')
    values <- c(
      stubs_generated = created + appended,
      stubs_created = created,
      stubs_appended = appended,
      stubs_skipped = sum(grepl('skipped', scaffold$action)),
      stubs_protected = sum(actions == 'protected'),
      drift_count = nrow(drift),
      drift_endpoints = length(unique(drift$endpoint))
    )
    cat(paste0(names(values), '=', values, '\n'), file = Sys.getenv('GITHUB_OUTPUT'), append = TRUE)
  }
  invisible(result)
}
if (sys.nframe() == 0L) {
  generate_stubs_main()
}
