# Development-only toolkit; use committed source, never the source working tree.
verify_specmill <- function(
  lib = 'dev/specmill-pilot/artifacts/toolkit-library',
  lock = 'dev/specmill-lock.json'
) {
  pin <- jsonlite::read_json(lock)
  lib <- normalizePath(lib, mustWork = TRUE)
  expected <- normalizePath(file.path(lib, pin$package), mustWork = TRUE)
  namespace <- loadNamespace(pin$package, lib.loc = lib)
  loaded <- normalizePath(getNamespaceInfo(namespace, 'path'), mustWork = TRUE)
  if (!identical(loaded, expected)) {
    stop('Wrong specmill namespace is already loaded: ', loaded, '. Restart R and load the isolated toolkit library.')
  }
  description <- utils::packageDescription(pin$package, lib.loc = lib)
  if (
    !identical(description[['Config/specmill/source-commit']], pin$source_commit) ||
      !identical(description[['Config/specmill/source-archive-sha256']], pin$source_archive_sha256)
  ) {
    stop('Installed specmill source provenance does not match dev/specmill-lock.json.')
  }
  message(
    'Verified specmill ',
    description$Version,
    ' at ',
    loaded,
    '\nSource revision: ',
    pin$source_commit,
    '\nSource archive SHA256: ',
    pin$source_archive_sha256
  )
  invisible(namespace)
}

install_specmill <- function(
  lib = 'dev/specmill-pilot/artifacts/toolkit-library',
  source_repo = Sys.getenv('SPECMILL_SOURCE_REPO', '../specmill'),
  lock = 'dev/specmill-lock.json'
) {
  pin <- jsonlite::read_json(lock)
  if ('specmill' %in% loadedNamespaces()) {
    stop('Install specmill in a fresh R process so namespace verification is reliable.')
  }
  source_repo <- normalizePath(source_repo, mustWork = TRUE)
  work <- tempfile('specmill-source-')
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  archive <- file.path(work, 'source.tar')
  status <- system2(
    'git',
    c('-C', shQuote(source_repo), 'archive', '--format=tar', paste0('--output=', shQuote(archive)), pin$source_commit)
  )
  if (status != 0L) {
    stop('Cannot archive the pinned specmill revision.')
  }
  if (!identical(digest::digest(file = archive, algo = 'sha256'), pin$source_archive_sha256)) {
    stop('Pinned specmill source archive checksum mismatch.')
  }
  source <- file.path(work, 'source')
  dir.create(source)
  utils::untar(archive, exdir = source)
  description <- file.path(source, 'DESCRIPTION')
  metadata <- as.list(read.dcf(description)[1L, ])
  metadata[['Config/specmill/source-commit']] <- pin$source_commit
  metadata[['Config/specmill/source-archive-sha256']] <- pin$source_archive_sha256
  write.dcf(as.data.frame(metadata, check.names = FALSE), file = description)
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  lib <- normalizePath(lib, mustWork = TRUE)
  executable <- file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'R.exe' else 'R')
  status <- system2(executable, c('CMD', 'INSTALL', paste0('--library=', shQuote(lib)), shQuote(source)))
  if (status != 0L) {
    stop('Pinned specmill installation failed.')
  }
  verify_specmill(lib, lock)
  invisible(lib)
}

if (sys.nframe() == 0L) {
  install_specmill()
}
