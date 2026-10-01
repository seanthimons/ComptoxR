# Offline rehearsal only; this never overwrites the live client's helpers.
stage_issue342 <- function(root = 'dev/specmill-pilot/artifacts/issue-342-rehearsal') {
  source('dev/install_specmill.R', local = TRUE)
  verify_specmill()
  if (file.exists(root)) {
    stop('Rehearsal destination already exists: ', root)
  }
  dir.create(root, recursive = TRUE)
  archive <- tempfile(fileext = '.tar')
  on.exit(unlink(archive), add = TRUE)
  status <- system2('git', c('archive', '--format=tar', paste0('--output=', shQuote(archive)), 'HEAD'))
  if (status != 0L) {
    stop('Cannot archive the current committed client.')
  }
  utils::untar(archive, exdir = root)
  stopifnot(file.copy('dev/specmill-lock.json', file.path(root, 'dev/specmill-lock.json'), overwrite = TRUE))
  status <- system2('git', c('apply', paste0('--directory=', shQuote(root)), 'dev/specmill-342/compatibility.patch'))
  if (status != 0L) {
    stop('Compatibility patch no longer applies; review before adoption.')
  }
  scaffold <- specmill:::request_helper_scaffold(
    '.ct_request',
    'https://example.invalid',
    NULL,
    'COMPTOXR_NATIVE_DRY_RUN',
    companions = 'batching'
  )
  dir.create(file.path(root, '.specmill/helpers'), recursive = TRUE, showWarnings = FALSE)
  writeLines(scaffold$code, file.path(root, 'R/z_specmill_request.R'))
  writeLines(scaffold$provenance, file.path(root, '.specmill/helpers/.ct_request.json'))
  message('Staged compatibility candidate at ', root)
  invisible(root)
}

if (sys.nframe() == 0L) {
  stage_issue342()
}
