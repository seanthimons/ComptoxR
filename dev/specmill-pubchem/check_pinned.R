# Read-only full freshness check against this checkout's unchanged toolkit pin.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L)
source('dev/install_specmill.R')
verify_specmill(lib = args[[1L]])
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
plan <- specmill::generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'check', artifacts = c('wrappers', 'tests'), validation = TRUE)
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics),
  !length(plan$drift), !length(plan$retained_diagnostics))
saveRDS(list(version = as.character(packageVersion('specmill')), diagnostics = plan$diagnostics,
  mapping_diagnostics = plan$mapping_diagnostics, drift = plan$drift, files = plan$files),
  'dev/specmill-pubchem/baseline-freshness.rds', version = 3)
print(plan)
