# Client inspection from the same explicit inputs as generation.
.toolkit_root <- apipak::script_root('toolkit_adapter.R')
comptox_inventory <- function(root = .toolkit_root) {
  callbacks <- new.env(parent = baseenv())
  sys.source(file.path(root, 'dev/apipak_callbacks.R'), envir = callbacks)
  apipak::inspect_client(root, callbacks = callbacks)
}
