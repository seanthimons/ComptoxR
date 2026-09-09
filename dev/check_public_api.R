# Check the current source, an expanded source package, or a rendered site.
.public_api_root <- apipak::script_root('check_public_api.R')
check_public_api <- function(root = .public_api_root, membership = dir.exists(file.path(root, 'dev'))) {
  selected <- if (membership) {
    callbacks <- new.env(parent = baseenv())
    sys.source(file.path(root, 'dev/apipak_callbacks.R'), envir = callbacks)
    vapply(apipak::inspect_client(root, callbacks = callbacks)$operations, `[[`, character(1), 'name')
  } else {
    NULL
  }
  apipak::check_public_boundary(root, file.path(.public_api_root, 'dev/apipak-public.yml'), selected)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  check_public_api(if (length(args)) args[[1]] else .public_api_root)
}
