# Install the reviewed development engine. It is not a client runtime dependency.
install_toolkit <- function(lib = .libPaths()[1L], lock = 'dev/toolkit-lock.json') {
  pin <- jsonlite::read_json(lock)
  archive <- tempfile(fileext = '.tar.gz')
  on.exit(unlink(archive), add = TRUE)
  curl::curl_download(pin$url, archive, quiet = TRUE)
  if (!identical(digest::digest(file = archive, algo = 'sha256'), pin$sha256)) {
    stop('Toolkit source checksum does not match the reviewed revision.')
  }
  executable <- file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'R.exe' else 'R')
  status <- system2(executable, c('CMD', 'INSTALL', paste0('--library=', shQuote(lib)), shQuote(archive)))
  if (status != 0L) {
    stop('Toolkit installation failed.')
  }
  stopifnot(as.character(utils::packageVersion(pin$package, lib.loc = lib)) == pin$version)
  invisible(lib)
}

if (sys.nframe() == 0L) {
  install_toolkit()
}
