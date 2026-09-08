generator_parity <- function(root = '.') {
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  baseline <- file.path(root, 'dev/migration-evidence/.render-baseline')
  dir.create(baseline, showWarnings = FALSE)
  archive <- tempfile(fileext = '.zip')
  old <- setwd(root)
  on.exit(setwd(old), add = TRUE)
  status <- system2(
    'git',
    c(
      'archive',
      '--format=zip',
      paste0('--output=', shQuote(archive)),
      '8f055b8',
      'R',
      'schema',
      'inst',
      'dev',
      'DESCRIPTION',
      'NAMESPACE',
      'data/testing_chemicals.rda'
    )
  )
  stopifnot(status == 0L)
  utils::unzip(archive, exdir = baseline)
  runner <- file.path(root, 'dev/migration-evidence/generator-parity.R')
  status <- system2(
    file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'Rscript.exe' else 'Rscript'),
    c(shQuote(runner), '--baseline', shQuote(baseline)),
    stdout = file.path(root, 'dev/migration-evidence/toolkit-old-generator.log'),
    stderr = file.path(root, 'dev/migration-evidence/toolkit-old-generator.log')
  )
  stopifnot(status == 0L)
  generated <- file.path(root, 'dev/migration-evidence/.render-installed')
  dir.create(generated, showWarnings = FALSE)
  stopifnot(all(file.copy(
    file.path(root, c('R', 'schema', 'inst', 'DESCRIPTION', 'NAMESPACE')),
    generated,
    recursive = TRUE,
    overwrite = TRUE
  )))
  dir.create(file.path(generated, 'data'), showWarnings = FALSE)
  stopifnot(file.copy(file.path(root, 'data/testing_chemicals.rda'), file.path(generated, 'data'), overwrite = TRUE))
  dir.create(file.path(generated, 'dev'), showWarnings = FALSE)
  dev_files <- list.files(file.path(root, 'dev'), full.names = TRUE)
  dev_files <- dev_files[!basename(dev_files) %in% c('migration-evidence', 'logs')]
  stopifnot(all(file.copy(dev_files, file.path(generated, 'dev'), recursive = TRUE, overwrite = TRUE)))
  adapter <- new.env(parent = globalenv())
  sys.source(file.path(root, 'dev/toolkit_adapter.R'), envir = adapter)
  adapter$generate_comptox(generated, 'apply', rebuild = c('ct', 'chemi', 'epi'))
  paths <- function(dir) c(file.path('R', list.files(file.path(dir, 'R'), '\\.R$')), 'inst/hook_config_generated.yml')
  stopifnot(identical(sort(paths(baseline)), sort(paths(generated))))
  canonical <- function(dir) {
    setNames(
      lapply(paths(dir), function(path) {
        file <- file.path(dir, path)
        if (grepl('\\.R$', path)) {
          list(
            code = lapply(parse(file, keep.source = FALSE), function(x) deparse(x, width.cutoff = 500L)),
            docs = grep("^#'", readLines(file, warn = FALSE), value = TRUE)
          )
        } else {
          yaml::read_yaml(file)
        }
      }),
      paths(dir)
    )
  }
  a <- canonical(baseline)
  b <- canonical(generated)
  different <- names(a)[!vapply(names(a), function(name) identical(a[[name]], b[[name]]), logical(1))]
  if (length(different)) {
    writeLines(
      capture.output(all.equal(a[[different[[1]]]], b[[different[[1]]]])),
      file.path(root, 'dev/migration-evidence/toolkit-first-difference.txt')
    )
  }
  writeLines(
    c(sprintf('Compared %d generated/protected files', length(a)), sprintf('Differences: %d', length(different))),
    file.path(root, 'dev/migration-evidence/toolkit-render-parity.txt')
  )
  stopifnot(length(different) == 0L)
  before <- tools::md5sum(file.path(generated, paths(generated)))
  adapter$generate_comptox(generated, 'apply')
  stopifnot(identical(before, tools::md5sum(file.path(generated, paths(generated)))))
  cat('Old and installed generators match code, signatures, docs, generated hook metadata and second-pass hashes.\n')
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) && args[[1]] == '--baseline') {
    setwd(args[[2]])
    here::i_am('dev/generate_stubs.R')
    source('dev/remove_experimental.R')
    for (prefix in c('ct', 'chemi', 'epi')) {
      selected <- scan_experimental_files('R', prefix)
      unlink(selected$file[selected$status == 'selected'])
    }
    source('dev/generate_stubs.R')
  } else {
    generator_parity()
  }
}
