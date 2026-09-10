# Client inspection from the same explicit inputs as generation.
.toolkit_root <- specmill::script_root('toolkit_adapter.R')
comptox_inventory <- function(root = .toolkit_root) {
  callbacks <- new.env(parent = baseenv())
  sys.source(file.path(root, 'dev/specmill_callbacks.R'), envir = callbacks)
  specmill::inspect_client(root, callbacks = callbacks)
}
