# Check the current source, an expanded source package, or a rendered site.
check_public_api <- function(root = '.') {
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  files <- if (file.exists(file.path(root, '.git'))) {
    paths <- system2('git', c('-C', shQuote(root), 'ls-files'), stdout = TRUE)
    stopifnot(is.null(attr(paths, 'status')))
    file.path(root, paths)
  } else {
    list.files(root, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  }
  files <- files[file.exists(files) & !dir.exists(files)]
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
  }
  schemas <- list.files(file.path(root, 'schema'), '-(dev|staging)[.]json$')
  stopifnot(!length(schemas))
  cat(sprintf('Public boundary passed: %d text files scanned.\n', length(text_files)))
  invisible(TRUE)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  check_public_api(if (length(args)) args[[1]] else '.')
}
