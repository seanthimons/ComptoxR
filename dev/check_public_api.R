# Check the current source, an expanded source package, or a rendered site.
check_public_api <- function(root = '.', membership = dir.exists(file.path(root, 'dev'))) {
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  files <- list.files(root, recursive = TRUE, full.names = TRUE)
  text_files <- files[grepl('[.](R|Rd|md|Rmd|json|ya?ml|html|xml|txt|csv|js)$', files)]
  forbidden_host <- paste0(
    'ctx-api-(stg|dev)[.]|comptoxstaging[.]|',
    'cim(-dev)?[.]sciencedataexperts[.]|hazard-dev[.]sciencedataexperts[.]|',
    'ccte-cced-cheminformatics[.]'
  )
  hits <- text_files[vapply(
    text_files,
    function(f) {
      any(grepl(forbidden_host, readLines(f, warn = FALSE), ignore.case = TRUE))
    },
    logical(1)
  )]
  if (length(hits)) {
    stop('Non-production address found: ', paste(hits, collapse = ', '))
  }
  owned <- files[grepl('/(R|man|reference)/', files)]
  stopifnot(!any(grepl('_(staging|development)[.]', basename(owned))))
  namespace <- file.path(root, 'NAMESPACE')
  if (file.exists(namespace)) {
    exports <- sub('^export\\((.*)\\)$', '\\1', grep('^export\\(', readLines(namespace), value = TRUE))
    stopifnot(!any(grepl('_(staging|development)$', exports)), !'chemi_safety' %in% exports)
    if (membership) {
      adapter <- new.env(parent = globalenv())
      sys.source(file.path(root, 'dev/toolkit_adapter.R'), envir = adapter)
      context <- adapter$comptox_tools(root)
      schema_names <- unlist(lapply(context$api_specs, function(spec) spec$build_endpoints()$fn))
      manual <- c(
        'chemi_classyfire',
        'chemi_functional_use',
        'chemi_predict',
        'chemi_safety_section',
        'chemi_server',
        'chemi_toxprint',
        'ct_api_key',
        'ct_classify',
        'ct_related',
        'ct_similar',
        'epi_server'
      )
      api <- grep('^(ct_|chemi_|epi_)', exports, value = TRUE)
      missing <- setdiff(api, c(schema_names, manual))
      if (length(missing)) {
        stop('Export has no approved production mapping: ', paste(missing, collapse = ', '))
      }
      schemas <- list.files(file.path(root, 'schema'), '-(dev|staging)[.]json$')
      stopifnot(!length(schemas))
    }
  }
  cat(sprintf('Public boundary passed: %d text files scanned.\n', length(text_files)))
  invisible(TRUE)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  check_public_api(if (length(args)) args[[1]] else '.')
}
