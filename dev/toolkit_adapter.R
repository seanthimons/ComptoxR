# Development-only adapter. Every client path is rooted in this explicit checkout.
comptox_tools <- function(root) {
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  context <- new.env(parent = asNamespace('wrapmaint'))
  context$toolkit_root <- root
  sys.source(file.path(root, 'dev/stub_specs.R'), envir = context)
  context
}

generate_comptox <- function(root, mode = c('check', 'plan', 'apply'), rebuild = character()) {
  mode <- match.arg(mode)
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  stage <- tempfile('comptox-generation-')
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  inputs <- c('R', 'schema', 'inst', 'DESCRIPTION', 'NAMESPACE')
  stopifnot(all(file.copy(file.path(root, inputs), stage, recursive = TRUE)))
  dir.create(file.path(stage, 'data'))
  stopifnot(file.copy(file.path(root, 'data/testing_chemicals.rda'), file.path(stage, 'data')))
  dir.create(file.path(stage, 'dev'))
  dev_files <- list.files(file.path(root, 'dev'), full.names = TRUE)
  dev_files <- dev_files[!basename(dev_files) %in% c('migration-evidence', 'logs')]
  stopifnot(all(file.copy(dev_files, file.path(stage, 'dev'), recursive = TRUE)))
  ownership <- new.env(parent = baseenv())
  sys.source(file.path(root, 'dev/remove_experimental.R'), envir = ownership)
  for (prefix in rebuild) {
    selected <- ownership$scan_experimental_files(file.path(stage, 'R'), prefix)
    unlink(selected$file[selected$status == 'selected'])
  }
  context <- comptox_tools(stage)
  context$reset_endpoint_tracking()
  results <- lapply(context$api_specs, context$run_generator, pkg_dir = file.path(stage, 'R'))
  # Preserve the existing formatter step for newly generated Chemi wrappers.
  generated_files <- unlist(
    lapply(results, function(result) {
      if (!all(c('written', 'path') %in% names(result$scaffold))) {
        return(character())
      }
      result$scaffold$path[result$scaffold$written & grepl('[/\\\\]chemi_', result$scaffold$path)]
    }),
    use.names = FALSE
  )
  if (length(generated_files) && nzchar(Sys.which('air'))) {
    stopifnot(system2('air', c('format', shQuote(generated_files))) == 0L)
  }
  files <- c(file.path('R', list.files(file.path(stage, 'R'), '\\.R$')), 'inst/hook_config_generated.yml')
  original <- c(file.path('R', list.files(file.path(root, 'R'), '\\.R$')), 'inst/hook_config_generated.yml')
  files <- files[file.exists(file.path(stage, files))]
  output <- setNames(
    lapply(file.path(stage, files), function(path) paste(readLines(path, warn = FALSE), collapse = '\n')),
    files
  )
  generated_metadata <- normalizePath(
    file.path(root, 'inst/hook_config_generated.yml'),
    winslash = '/',
    mustWork = FALSE
  )
  owns <- function(path) {
    if (identical(normalizePath(path, winslash = '/', mustWork = FALSE), generated_metadata)) {
      return(TRUE)
    }
    identical(ownership$classify_experimental_file(path)$status, 'selected')
  }
  changes <- wrapmaint::apply_files(root, output, remove = setdiff(original, files), mode = mode, owned = owns)
  invisible(list(
    files = changes,
    results = results,
    manifest = list(
      toolkit = as.character(utils::packageVersion('wrapmaint')),
      schemas = tools::md5sum(list.files(file.path(root, 'schema'), '\\.json$', full.names = TRUE)),
      hooks = tools::md5sum(file.path(root, 'inst/hook_config.yml')),
      policy_version = 'comptox-compatibility-1',
      policy = tools::md5sum(file.path(
        root,
        c(
          'dev/stub_specs.R',
          'dev/endpoint_eval/00_config.R',
          'dev/endpoint_eval/06_param_parsing.R',
          'dev/endpoint_eval/07_stub_generation.R',
          'dev/toolkit_adapter.R'
        )
      ))
    )
  ))
}
