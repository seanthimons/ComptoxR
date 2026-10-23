# Reproduce the reviewed facade patch and native helper in a disposable checkout.
stage_issue342 <- function(root = 'dev/specmill-pilot/artifacts/issue-342-adoption-reproduction') {
  source('dev/install_specmill.R', local = TRUE)
  verify_specmill()
  if (file.exists(root)) {
    stop('Rehearsal destination already exists: ', root)
  }
  dir.create(root, recursive = TRUE)
  archive <- tempfile(fileext = '.tar')
  on.exit(unlink(archive), add = TRUE)
  review <- jsonlite::read_json('dev/specmill-342/adoption.json')
  status <- system2('git', c('archive', '--format=tar', paste0('--output=', shQuote(archive)), review$base_commit))
  if (status != 0L) {
    stop('Cannot archive the current committed client.')
  }
  utils::untar(archive, exdir = root)
  stopifnot(file.copy('dev/specmill-lock.json', file.path(root, 'dev/specmill-lock.json'), overwrite = TRUE))
  status <- system2('git', c('apply', paste0('--directory=', shQuote(root)), 'dev/specmill-342/compatibility.patch'))
  if (status != 0L) {
    stop('Compatibility patch no longer applies; review before adoption.')
  }
  source('dev/specmill-342/emit.R', local = TRUE)
  emit_issue342(root, mode = 'apply')
  message('Staged compatibility candidate at ', root)
  invisible(root)
}

if (sys.nframe() == 0L) {
  stage_issue342()
}
